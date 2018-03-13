package Scot::Controller::Auth;

use lib '../../../lib';
use v5.18;
use MIME::Base64;
use Crypt::PBKDF2;
use Data::Dumper;
use Data::UUID;
use Try::Tiny;
use strict;
use warnings;

use base 'Mojolicious::Controller';

=head1 Scot::Controller::Auth

Authentication and Authorization 

=cut

=item B<check>

This sub gets called on every route under /scot.  This routine checks the authentication
status of the request.

    First, we look for a mojolicious session.  
    The presence of that indicates that 
    the use has been authenticated and we can return true.

    Second, we look for an API token.  If we find a valid one, then we are good.
    Finally, we either do a Local authentication or 
    we redirect to an Apache Authentication
    landing that will do SSO for us.

=cut

sub check {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $request = $self->req;
    my $user    = '';
    my $headers = $request->headers;

    my $loglevel = $log->level;
    $log->level(Log::Log4perl::Level::to_priority('INFO'));

    $log->debug("Authentication Check Begins...");

    if ( $env->auth_type eq "Testing" ) {
        $log->warn("in test mode, NO AUTHENTICATION");
        $user   = "scot-testing";
        $log->level($loglevel);
        return $self->sucessful_auth({
            user    => $user,
            method  => "testing"});
    }

    if ( $user = $self->valid_mojo_session ) {
        $self->update_lastvisit($user);
        my $groups = $self->set_group_membership($user);
        if (defined $groups) {
            $log->info("Authenticated (mojo) User $user (".join(',',@$groups).")");
            $log->level($loglevel);
            return 1;
        }
        else {
            $log->level($loglevel);
            return undef;
        }
    }

    if ( $user = $self->valid_authorization_header($headers) ) {
        $log->level($loglevel);
        return $self->sucessful_auth({
            user    => $user,
            method  => "apikey"});
    }

    if ( $user = $self->sso($headers) ) {
        $log->level($loglevel);
        return $self->sucessful_auth({
            user    => $user,
            method  => "sso"});
    }

    $log->error("Failed Authentication Check");
    $self->session(orig_url => $request->url->to_string );
    # $self->redirect_to('/login');
    $self->render(
        status  => 401,
        json    => { 
            error => "Authentication Required",
            csrf  => $self->csrf_token,
        }
    );
    $log->level($loglevel);
    return undef;
}


=item B<login>

this route will generate a web based form for login

=cut

sub login {
    my $self    = shift;
    my $href    = { status => "fail" };
    my $log     = $self->env->log;
    my $url     = $self->session('orig_url');
    $log->debug("rendering login form");
    $self->render( orig_url => $url );
}

=item B<logout>

this route will clear the session cookie that will force a 
reauthentication, although if you are using basic auth, the
browser may need to be quick and restarted to fully log out.

=cut

sub logout {
    my $self    = shift;
    $self->session( user    => '' );
    $self->session( groups  => '' );
    $self->session( expires => 1 );
    $self->render(
        status  => 200,
        orig_url => '/',
        json    => {
            result  => "user logged out"
        });
}

=item B<auth>

this is the route that the form posts username and password to
we then check for validity and then try to authenticate via 
ldap and then local

=cut


sub auth {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $user    = lc($self->param('user'));
    my $pass    = $self->param('pass');
    my $origurl = $self->session('orig_url');

    $log->debug("Form based Login.  User = $user orig_url = $origurl");
    $log->debug("Auth Type = ".$env->auth_type);

    # remove leading and trailing spaces from password
    # sometimes happens with forms
    $pass =~ s/^\s+(\w+)\s+$/$1/;

    $log->debug("checking validity of username and password");
    if ( $self->invalid_user_pass($user, $pass) ) {
        return $self->failed_auth("invalid user or password", $user);
    }

    $log->debug("attempting to authenticate via ldap");
    if ( $self->authenticate_via_ldap($user, $pass) ) {
        return $self->sucessful_auth({
            user    => $user, 
            url     => $origurl,
            method  => "ldap"});
    }

    $log->debug("attempting to authenticate via local");
    if ( $self->authenticate_via_local($user, $pass) ) {
        return $self->sucessful_auth({
            user    => $user,
            url     => $origurl,
            method  => "local"});
    }
     
    # all hope is lost
    $log->error("Failed all attempts to authenticate $user");
    return $self->failed_auth(
        "attempt to authenticate $user failed",
        $user
    );
}

=item B<sso>

this route is called to a route that will do the 
SSO (single sign on).  Essentially, we are relying 
on the apache config wrapped around the /sso location
to authenticate the user (via kerberos, or someother 
authentication system).  The apache config then 
sets a remote_user header that is passed to the 
scot server.  (this is ok because only the apache
server can talk to the scot server.)  If we pull
apache and scot apart to seperate systems we will
need to otherwise lock this connection down

=cut

sub sso {
    my $self    = shift;
    my $log     = $self->env->log;
    my $url     = $self->param('orig_url') // '/';
    $log->debug("SSO authentication attempt ($url)");
    if ( $url eq "/login" ) {
        $url    = "/";
    }

    my $request     = $self->req;
    my $headers     = $request->headers;
    my $remoteuser  = $headers->header('remote-user');

    unless ( $remoteuser ) {
        $log->debug("no remoteuser set");
        return undef;
    }

    $log->debug("Remoteuser set by Webserver as $remoteuser");

    if ( my $user = $self->valid_remoteuser($headers) ) {
        $self->sucessful_auth({
            user    => $user,
            url     => $url,
            method  => "remoteuser"});
        return $user;
    }
    $self->render(
        status  => 401,
        json    => { 
            error => "Authentication Required",
            csrf  => $self->csrf_token,
        }
    );
}

=item B<invalid_user_pass>

this subroutine checks for common problems in a
username or password

=cut

sub invalid_user_pass {
    my $self    = shift;
    my $user    = shift;
    my $pass    = shift;
    my $log     = $self->env->log;

    $log->debug("checking validity of username/password");

    unless ( defined $user and defined $pass ) {
        $log->error("undefined user or pass");
        return 1;
    }
    if ( $self->invalid_username($user) ) {
        $log->error("invalid username characters");
        return 1;
    }
    if ( length($user) > 32 or length($pass) > 32 ) {
        $log->error("user or pass was greater than 32 characters");
        return 1;
    }
    return undef;
}

=item B<authenticate_via_ldap>

return true if the ldap server is available and authenticates the user

=cut

sub authenticate_via_ldap {
    my $self    = shift;
    my $user    = shift;
    my $pass    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $type    = lc($env->auth_type);

    $log->debug("attempting authentication of $user by ldap");

    # what we want here is an attempt to use ldap, if it failes or ldap
    # not configured we move on

    # if ( defined $type ) {
    #     if ( $type eq "ldap" ) {
            if ( $self->ldap_authenticates($user, $pass) ) {
                $log->debug("$user authenticated via ldap");
                return 1;
            }
            else {
                $log->error("$user failed ldap authentication");
                return undef;
            }
    #     }
    #    else {
    #       $log->debug("skipping ldap attempt");
    #        return undef;
    #   }
    #}
    #else {
    #    $log->error("environment did not define auth_type, ".
    #                "skipping ldap attempt");
    #    return undef;
    #}
}

=item B<ldap_authenticates>

returns true if Scot::Util::Ldap->authenticate_user returns true

=cut

sub ldap_authenticates {
    my $self    = shift;
    my $user    = shift;
    my $pass    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $ldap    = $env->get_handle('ldap');

    $log->debug("seeing if ldap will authenticate");

    if ( defined $ldap ) {
        if ( $ldap->authenticate_user($user, $pass) ) {
            $log->debug("$user authenticated by ldap");
            return 1;
        }
        else {
            $log->error("$user failed ldap authentication");
            return undef;
        }
    }
    else {
        $log->error("ldap not loaded in env.  Assuming no LDAP configured.");
        return undef;
    }
}

=item B<authenticate_via_local>

authenticate a user against the users collection 

=cut

sub authenticate_via_local {
    my $self    = shift;
    my $user    = shift;
    my $pass    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    $log->debug("authenticating $user via local");

    my $col     = $mongo->collection('User');
    my $userobj = $col->find_one({ username => $user});

    if (defined($userobj)) {
        $log->debug("User $user is in user collection");
        my $pwhash  = $userobj->pwhash;

        if ( defined $pwhash ) {
            if ( $pwhash =~ /X-PBKDF2/ ) {
                my $pbkdf2 = Crypt::PBKDF2->new(
                    hash_class  => 'HMACSHA2',
                    hash_args   => { sha_size => 512 },
                    iterations  => 10000,
                    salt_len    => 15,
                );

                if ( $pbkdf2->validate($pwhash, $pass) ) {
                    my $active = $userobj->active;
                    if ( defined $active and $active == 0 ) {
                        $log->error("$user is not active");
                        return undef;
                    }
                    return 1;
                }
                else {
                    $log->error("$user entered invalid password");
                    return undef;
                }

            }
            else {
                $log->error("$user has no local pw or stored hash invalid");
                return undef;
            }
        }
        else {
            $log->error("User does not have a PW hash stored");
            return undef;
        }
    }
    $log->error("No user matching $user in user collection");
    return undef;
}

=item B<valid_mojo_session>

checks for the presence of a valid mojo session cookie

=cut

sub valid_mojo_session {
    my $self    = shift;
    my $log     = $self->env->log;

    $log->debug("Looking for Mojo session cookie");
    
    my $user    = $self->session('user');
    if ( defined $user ) {
        $log->debug("User $user has valid mojo session.");
        return $user;
    }

    $log->debug("Invalid or undefined Mojo Session");
    return undef;
}

=item B<valid_authorization_header>

checks for either basic or api in the Authorization key

=cut

sub valid_authorization_header {
    my $self    = shift;
    my $headers = shift;
    my $log     = $self->env->log;
    my $user;

    $log->debug("checking for valid authorization header");

    my $auth_header     = $headers->header('authorization');

    if ( defined $auth_header ) {

        $log->debug("Authorization header = $auth_header");

        my ($type,$value)   = split(/ /, $auth_header, 2);

        if ( $type =~ /basic/i ) {
            $log->debug("Basic Authentication Attempt...");
            if ( $user = $self->validate_basic($value) ) {
                $log->debug("User $user appears authentic");
                return $user;
            }
            else {
                $log->error("Invalid or disallowed user");
                return undef;
            }
        }

        if ( $type =~ /apikey/i ) {
            $log->debug("ApiKey Authentication Attempt...");
            if ( $user = $self->validate_apikey($value) ) {
                $log->debug("User $user used apikey");
                return $user;
            }
            else {
                $log->error("Invalid api key");
                return undef;
            }
        }

        $log->error("Invalid Authentication type in Authentication Header");
    }
    else {
        $log->error("no authorization header present");
    }
    return undef;
}

sub validate_basic {
    my $self    = shift;
    my $value   = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $decoded         = decode_base64($value);
    my ($user, $pass)   = split(/:/,$decoded,2);

    if ( $self->authenticate_via_ldap($user, $pass) ) {
        $log->debug("$user authenticated via ldap");
        return $user;
    }

    if ( $self->authenticate_via_local($user, $pass) ) {
        $log->debug("$user authenticated via local");
        return $user;
    }
    return undef;
}

sub validate_apikey {
    my $self    = shift;
    my $value   = shift;
    my $log     = $self->env->log;

    $log->debug("validating apikey = $value");

    # my $decoded = decode_base64($value);
    my $decoded = $value;
    
    if ( my $user = $self->authenticate_via_apikey($decoded) ) {
        $log->debug("Authentic api key used");
        return $user;
    }
    return undef;
}

sub authenticate_via_apikey {
    my $self    = shift;
    my $key     = shift;
    my $log     = $self->env->log;

    $log->debug("key is $key");

    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Apikey');
    my $keyobj  = $col->find_one({apikey => $key});

    if ( defined $keyobj ) {
        $log->debug("API Key Found");
        if ( $keyobj->active == 1 ) {
            $log->debug("apikey is active");
            return $keyobj->username;
        }
        else {
            $log->error("inactive api key attempt");
            return undef;
        }
    }
    else {
        $log->error("non matching api key attempt");
        return undef;
    }
}

=item B<valid_remoteuser>

checks for a valid remote user

=cut

sub valid_remoteuser {
    my $self    = shift;
    my $headers = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $remoteuser  = $headers->header('remote-user');

    if ( defined $remoteuser ) {
        $log->debug("Remoteuser detected, and that is good enough for me. ");
        return $remoteuser;
    }
    else {
        $log->error("Remoteuser not set");
    }
    return undef;
}

sub set_group_membership {
    my $self    = shift;
    my $user    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("Set Group Membership");

    my $groups  = $self->session('groups');
    if ( ref($groups) eq "ARRAY" ) {
        $log->debug("Groups set in Mojo Session");
        $log->debug("$user Groups are ".join(', ',@$groups));
        if ( scalar(@$groups) > 0 ) {
            return $groups;
        }
    }

    $log->debug("Group membership not in session, fetching...");
    $groups = $self->get_groups($user);

    if ( scalar(@$groups) > 0 ) {
        $log->debug("Got 1 or more groups, storing in session");
        $self->session(groups => $groups);
        return $groups;
    }
    else {
        $log->error("User has null group set!");
        return undef;
    }
}

sub get_groups {
    my $self    = shift;
    my $user    = shift;
    my $env     = $self->env;
    my $log     = $self->env->log;
    my $mode    = $self->env->group_mode;
    my @groups  = ();
    my $results;

    $log->debug("Getting groups for user $user with mode $mode");

    # testing short circuit
    if ( $user eq "scot-testing" ) {
        push @groups, @{$self->env->default_groups->{modify}};
        return wantarray ? @groups :\@groups;
    }

    my $envmeta = $env->meta;

    if ( $envmeta->has_attribute('ldap') and $mode ne "local" ) {
        my $ldap = $self->env->ldap;

        if ( defined $ldap ) {
            $results = $ldap->get_users_groups($user);
            if ( ref($results) eq "ARRAY" ) {
                # return array
                push @groups, grep {/scot/i} @$results;
                return wantarray ? @groups : \@groups;
            }
            else {
                $log->warn("ldap failed to get groups: ".$results);
            }
        }

    }

    $log->debug("last attempt to get groups, local");
    my $mongo   = $self->env->mongo;
    my $ucol    = $mongo->collection("User");
    my $userobj    = $ucol->find_one({username => $user});

    if ( defined $userobj ) {
        $results    = $userobj->groups;
    }
    else {
        $log->error("User $user, not in local user collection!");
    }
    $log->debug("Got these groups: ",{filter=>\&Dumper, value=>$results});
    if ( ref($results) eq "ARRAY" ) {
        push @groups, grep {/scot/i} @$results;
    }
    else {
        $log->error("group fetch results in something other than an array! $results");
    }
    return wantarray ? @groups : \@groups;
}

sub invalid_username {
    my $self    = shift;
    my $user    = shift;
    # help prevent ldap injection
    unless ( $user =~ m/^[a-zA-Z0-9_@=\-]+$/ ) {
        $self->env->log->error("Invalid username chars detected! $user");
        $self->respond_401;
        return 1;
    }
    return undef;
}

sub respond_401 {
    my $self = shift;
    $self->render(
        status  => 401,
        json    => { error => "invalid username" }
    );
}

sub update_lastvisit {
    my $self    = shift;
    my $user    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    $log->trace("[User $user] update lastvisit time");

    my $url = $self->url_for('current');

    if ($url eq "/scot/api/v2/status" 
        or $url eq "/scot/api/v2/who" ) {
        $log->debug("skipping setting last visit for /status or /who");
        return;
    }

    my $col = $mongo->collection('User');
    my $obj = $col->find_one({username => $user});

    if ( $obj ) {
        $obj->update_set( lastvisit => $env->now );
    }
    else {
        $log->error("Weird, user $user is not in User collection!");
    }
}

sub update_user_sucess {
    my $self    = shift;
    my $user    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    $log->trace("Updating User $user Authentication Sucess");

    my $collection  = $mongo->collection("User");
    my $userobj     = $collection->find_one({username => $user});

    if ( defined $userobj ) { 
        $log->trace("User object $user retrieved");
        $userobj->update_set( attempts => 0);
        $userobj->update_set( lockouts => 0);
        $userobj->update_set( lastvisit=> $self->env->now);
        $userobj->update_set( last_login_attempt => $env->now );
    }
    else {
        $log->error("User $user not in DB.  Assuming New User");
        try {
            $userobj    = $collection->create(
                username    => $user,
                lastvisit   => $self->env->now,
                theme       => 'default',
                flair       => 'on',
                display_orientation => 'horizontal',
                attempts    => 0,
            );
        }
        catch {
            $log->error("Failed to create User $user! $_");
        };
    }
}

sub update_user_failure {
    my $self        = shift;
    my $username    = shift;
    my $mongo       = $self->env->mongo;
    my $log         = $self->env->log;

    $log->trace("Updating User $username failure to authenticate");

    my $collection  = $mongo->collection('User');
    my $user        = $collection->find_one({username    => $username});

    if ( $user ) {
        $user->update_inc(attempts => 1);
        if ( $user->attempts > 10) {
            $user->update_inc(lockouts => 1);
        }
        $user->update_set(last_login_attempt => $self->env->now);
    }
    else {
        $log->error("Unknown user $user failed attempted authentication!");
    }
}

sub sucessful_auth {
    my $self    = shift;
    my $href    = shift;
    my $user    = $href->{user};
    my $url     = $href->{url};
    my $method  = $href->{method};
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("User $user sucessfully authenticated");

    if ( $user eq "scot-testing" ) {
        $log->debug("setting default groups for $user since in test mode");
    }

    my $groups  = $self->get_groups($user);

    $log->debug("Got groups : ",{filter=>\&Dumper, value=>$groups});

    $self->session('groups' => $groups);

    $log->debug("attempting to set user sucess");
    
    $self->update_user_sucess($user);

    my $expiration = $self->get_expiration;

    $log->debug("setting users session");

    $self->session(
        user    => $user,
        groups  => $groups,
        secure  => 1,
        expiration  => $expiration,
    );

    $log->info("User $user (".join(',',@$groups).") Authenticated via $method");

    if ( defined $url ) {
        $self->redirect_to($url);
    }
    return 1;
}

sub get_expiration {
    my $self    = shift;
    my $env     = $self->env;
    my $meta    = $env->meta;
    
    if ( $meta->has_attribute("session_expiration") ) {
        return $env->session_expiration;
    }
    return 3600 * 4;
}

sub failed_auth {
    my $self    = shift;
    my $msg     = shift;
    my $user    = shift;
    my $log     = $self->env->log;

    $log->error("$user failed authentication");

    $self->update_user_failure($user);

    $self->flash("Failed Authentication");
    # $self->redirect_to("/login");
    $self->render(
        status  => 401,
        json    => { 
            error => "Authentication Required",
            csrf  => $self->csrf_token,
        }
    );
    return;
}

sub get_apikey {
    my $self    = shift;
    my $user    = $self->session('user');
    my $groups  = $self->session('groups');
    my $log     = $self->env->log;

    unless (defined $user) {
        $log->error("unauthenticated user trying to get apikey!");
        $self->do_error(400, { error_msg => "missing user" });
        return;
    }

    my $ug  = Data::UUID->new;
    my $key = $ug->create_str();

    my $record  = {
        apikey      => $key,
        groups      => $groups,
        username    => $user,
    };

    my $collection  = $self->env->mongo->collection('Apikey');
    my $apikey      = $collection->api_create({
        request => {
            json    => $record
        }
    });

    $self->do_render({
        status  => 'ok',
        apikey  => $apikey->apikey,
    });
}

sub do_render {
    my $self    = shift;
    my $code    = 200;
    my $href    = shift;
    $self->render(
        status  => $code,
        json    => $href,
    );
}

1;
