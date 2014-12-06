package Scot::Util::Aaa;

# Authenticate
# Authorize
# Audit^H^H^H^H^HAwesome

use v5.10;
use strict;
use warnings;

use lib '../../../lib';
use MIME::Base64;
use Time::HiRes qw(usleep nanosleep);
use Net::LDAP;
use Data::Dumper;
use Digest::SHA qw(sha512_hex);
use Crypt::PBKDF2;

# use Log::Log4perl::Appender;
# use Log::Log4perl::Appender::File;
use Scot::Model::User;

use base 'Mojolicious::Controller';

# login catches when a user type "scotng.sandia.gov" into the browser
# or if they only type "scotng.sandia.gov/scot"

sub login {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
 
    my $return_href = {};
    if($self->check) {
        $return_href = {status => 'ok'};
    } else {
        $return_href = {status => 'fail'};
    }
    $self->render( json => $return_href );
    
}

sub get_xid {
    # in case we need some kind of transaction identifier in future
    # could use Data::GUID or somekind of generator in mongo
    return 0;
}

sub ldap_auth {
    my $self        = shift;
    my $user        = shift;
    my $password    = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;
    my $ldap        = $env->ldap;

    #TODO: Check password
    
    if ($ldap->authenticate_user($user, $password)) {

        $log->debug("authenticated user $user");

        my $groups = $ldap->get_users_groups($user);

        $log->debug("$user is in these groups: " . Dumper($groups));

        my $object      = $mongo->read_one_document({
            collection  => 'users',
            match_ref   => {'username' => $user},
        });

        if(!defined($user)) {
            my $user_obj    = Scot::Model::User->new({
                username    => $user,
                lastvisit   => $env->now(),
                theme       => "default",
                flair       => "on",
                display_orientation => "horizontal",
            });
            $mongo->create_document($user_obj);
        }

        $self->session(
            user    => $user,
            tz      => $self->get_timezone($user),
            groups  => $groups,
        );
        return 1;
    }
    return 0;
}

sub local_auth {
    my $self      = shift;
    my $env       = $self->env;
    my $log       = $env->log;
    my $mongo     = $env->mongo;
    my $user      = shift;
    my $password  = shift;
    
    my $obj   = $mongo->read_one_document({
        collection  => "users",
        match_ref   => { username   => $user },
    });
#         $log->debug('user query reponse' . Dumper($obj));

    if (defined $obj) {

        $log->debug('User exists, lets see if they have the right password');

        my $mHash = $obj->hash;

        $log->debug("mHash is ".Dumper($mHash));

        if ( defined ($mHash) && $mHash ne '' ) {

            $log->debug("Local Hash defined, validating...");

            my $pbkdf2 = Crypt::PBKDF2->new(
                hash_class  => 'HMACSHA2',
                hash_args   => { sha_size => 512 },
                iterations  => 10000,
                salt_len    => 15,
            );

            if(($pbkdf2->validate($mHash, $password))) {

                $log->debug("User has correct password, ".
                            "lets see if they are active");

                if($obj->active) {

                    $log->debug("User: $user is Active");

                    my $groups = $obj->groups;
                    # $log->debug("User in groups " . Dumper($groups));
                    $self->session(
                        user   => $user,
                        tz     => 'N/A',
                        groups => $groups,
                    );
                    return 1;
                } 
            } 
        } 
    }
    $log->debug("Local Auth failed");
    return undef;
}

sub respond_401 {
  my $self = shift;
  $self->res->headers->www_authenticate('Basic realm="SCOT"');
  $self->respond_to(
          any => {
            json => { error => 'Invalid authentication token.' },
            status => 401
          }
       );
}

# this is the function called by the bridge route
# we will use it to see if the user has authenticated to apache
# and to "audit" write to an access log

sub check {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mode    = $env->{mode};
    my $path    = $self->req->url->path;

    my $basicauth   = $self->req->headers->header('authorization');
    my $authuser    = $self->req->headers->header('authuser');
    # $log->debug("HEADERS".Dumper($self->req->headers));

    my $user        = $self->session('user');
    my $mongo       = $env->mongo;
    my $json        = $self->get_json;
    my $authmode    = $env->config->{$mode}->{authmode};

    $log->debug("authmod is ". $authmode);

    my $method = 'ldap';
    # $log->debug(Dumper($env));

    if ($authmode eq "test") {
        my $groups_aref = $env->config->{development}->{test_groups};
        $self->session( 
            user    => "scot-test", 
            groups  => $groups_aref,
            tz      => "MST7MDT" 
        );
        return 1;
    }

    if (!(defined $user)) {
        # user has not been previously authenticated

        $log->debug("User not previously authenticated...");

        if ( defined($basicauth) || 
            (defined($json) && defined($json->{'user'}))) { 
            # basic auth or form submittal

            $log->debug("Basic auth or json submittal");

            my $user;
            my $password;

            if (defined($basicauth)) {
	            (my $junk, $basicauth)  = split(/ /, $basicauth);
                $basicauth              = decode_base64($basicauth);
                ($user, $password)      = split(/:/, $basicauth);
                $log->debug("basicauth yields user = $user");
            } 
            else {
                    $user       = $json->{'user'};
                    $password   = $json->{'pass'};
            }

            if(!($user =~ m/^[a-zA-Z0-9_]+$/)) {
                # check for valid chars only in username
                $log->error("Invalid username chars detected");
                usleep(rand(1000000)); #sleep up to a second on incorrect login
                $self->respond_401;      
                return 0;
            }
            my $obj     = $mongo->read_one_document({
               collection  => "users",
               match_ref   => { username   => $user },
            });
            my $max_attempts = 10;
            my $result          = 0;

            if( defined($obj) && $
                obj->attempts > $max_attempts) {

                if(($env->now() - $obj->last_login_attempt) < 
                    (10 ** $obj->lockouts)) { 
                    $log->error('Denying user auth via local auth '.
                                '(but not ldap), since they reached '.
                                'limit of tries, user must wait ' . 
                                (10 ** $obj->lockouts) . 
                                ' seconds before their next login attempt');
                } 
                else { 
                    $log->debug('Resetting login attempt counter since lockout time has elapsed');
                    $obj->attempts(1);
                    $mongo->update_document($obj);
                    # Only try to validate locally if the user exists
                    $result = $self->local_auth($user, $password); 
                }
            }
            my $ldap_configured = $env->ldap->is_configured();

            $log->debug("LDAP IS Configured") if $ldap_configured;

            if( $ldap_configured && $result != 1 ) {
                # local didn't work so check ldap if configured
                $log->debug("localauth failed so trying ldap");
                $result = $self->ldap_auth($user, $password);
            } 
            else {
               $log->debug('LDAP Not configured, only doing local user auth');
            }

            if($result == 1) {
                Log::Log4perl::MDC->put("user", $user);
                if ( defined $obj ) {
                    $obj->attempts(0);
                    $obj->lockouts(0);
                    $mongo->update_document($obj);
                }
            } 
            else {
                if(defined($obj)) {
                   $obj->attempts($obj->attempts + 1);
                   if($obj->attempts == ($max_attempts + 1)) {
                      $obj->lockouts($obj->lockouts + 1);
                   }
                   $obj->last_login_attempt($env->now());
                   $mongo->update_document($obj);
                }
                $log->error("local and ldap both failed");
                usleep(rand(1000000)); #sleep up to a second on incorrect login
                $self->respond_401;
                return 0;
            }
       } 
       else {
          $self->respond_401;
          return 0;
       }
    } 
    else {
        Log::Log4perl::MDC->put("user", $user);
    }
    return 1;
}

sub is_permitted_group {
    my $self        = shift;
    my $group_aref  = shift;
    my $path        = shift;
    my $env         = $self->env;
    my $log         = $env->log;

    $path = lc($path);
    #if user is trying to access an admin url (begins with /admin) make sure they are in the admin group
    if ( index($path, '/scot/admin') == 0) {
        if( scalar( grep /admin/,@$group_aref ) ) {
            $log->debug("Admin in da' house!");
            return 1;
        } 
        else {
            return undef;
        }
    }

    #Check if the user is in the SCOT group for normal pages
    if ( scalar( grep /scot/,@$group_aref ) ) {
        $log->debug("welcome to the club");
        return 1;
    }
    return undef;
}

sub update_user_activity {
    my $self    = shift;
    my $user    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    $log->debug("update user activity");

# scot 2 way.  maybe we should write something similar in mongo.pm
#    $self->db->users->update(
#        { username  => $user },
#        { '$set'    => { lastvisit  => $self->now() } },
#        { safe      => 1,   upsert  => 1 },
#    );

    my $obj     = $mongo->read_one_document({
    #    'log'       => $log,
        collection  => "users",
        match_ref   => { username   => $user },
    });
    if (defined $obj) {
        $obj->lastvisit($env->now());
        $mongo->update_document($obj);
    }
    else {
        $log->error("No matching User, creating user record");
        my $user_obj    = Scot::Model::User->new({
            username    => $user,
            lastvisit   => $env->now(),
            theme       => "default",
            flair       => "on",
            display_orientation => "horizontal",
        });
        $mongo->create_document($user_obj);
    }
}

sub get_timezone {
    my $self    = shift;
    my $user    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $uobj    = $mongo->read_one_document({
        collection  => "users",
        match_ref   => { username => $user },
    });
    if ($uobj) {
        return $uobj->tzpref;
    }
    return "MST7MDT";
}

sub get_jabber_password {
    my $self        = shift;
    my $username    = shift;
    return undef unless $username;
    my $filename    = "/opt/sandia/webapps/scot3/jabber/$username";

    # If no password file exists, or password is older than 1 hours, 
    # replace with new password
    if ( (! -e $filename) || ((time - ((stat($filename))[9])) > 3600) ) {
        open FILE, ">$filename";
        print FILE createPassword(15); #Generate 15 character random password 
        close FILE; 
    }
    open FILE, "<$filename"; #read password from file
    my $result = <FILE>;
    close FILE;    
    return $result;
}

sub createPassword {
    my $length = shift;
    my $available = 'abcdefghijkmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    my $password = "";
    while (length($password) < $length) {
        $password .= substr($available, (int(rand(length($available)))), 1);
    }
    return $password
} 


1;
