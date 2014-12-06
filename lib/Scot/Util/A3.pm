package Scot::Util::A3;

use lib '../../../lib';
use v5.10;
use strict;
use warnings;

use MIME::Base64;
use Time::HiRes qw(usleep nanosleep);
use Net::LDAP;
use Digest::SHA qw(sha512_hex);
use Crypt::PBKDF2;

use Scot::Model::User;

use base 'Mojolicious::Controller';

sub login {
    my $self    = shift;
    my $href    = { status  => 'fail' };

    if ( $self->check ) {
        $href->{status} = "ok";
    }
    $self->render( json => $href );
}

sub check {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $path    = $self->req->url->path;

    $log->debug("AUTHENTICATION CHECK BEGINS");

    my $basicauth   = $self->req->headers->header('authorization');
    my $authuser    = $self->req->headers->header('authuser');
    my $json        = $self->get_json;
    my $user        = $self->session("user");

    return 1 if (defined $user);
    $log->debug("user not previously authenticated...");
    return 1 if $self->is_test_mode;
    $log->debug("we are not in test mode...");

    # see if user is even trying to authenticate
    return 0 if $self->not_trying_to_auth($basicauth, $json);
    $log->debug("trying to authenticate");

    # we have basic auth or form submittal
    ($user, my $pass)   = $self->get_user_pass($basicauth, $json);
    $log->debug("Got user $user with ".defined($pass) );

    # check to see if username is wonky
    return 0 if $self->has_invalid_user_chars($user);
    $log->debug("no invalid chars");

    # check for excessively long password
    return 0 if ( length($pass) > 32 );

    # Check if LDAP can authenticate
    if ( defined($self->env->ldap) ) {
        $log->debug("atteming ldap auth for user $user");
        if ( $self->ldap_authenticates($user,$pass) ) {
            $self->update_user_sucess($user);
            return 1;
        }
    }

    # ok, two strikes, check for local authentication
    if ( $self->local_authenticates($user, $pass) ) {
        $log->debug("atteming local auth");
        $self->update_user_sucess($user);
        return 1;
    }
    $log->debug("Unfortunately all attempts failed!");

    # too bad, so sad
    $self->update_user_failure($user);
    return 0;
}

sub ldap_authenticates {
    my $self    = shift;
    my $user    = shift;
    my $pass    = shift;

    my $ldap    = $self->env->ldap;
    my $log     = $self->env->log;

    unless (defined $ldap) {
        $log->error("LDAP is not defined!");
        return 0;
    }

    unless ($ldap->is_configured) {
        $log->error("LDAP not configured!");
        return 0;
    }

    return 0 unless ( $ldap->authenticate_user($user, $pass) ); 

    $log->debug("LDAP has authenticated user $user");

    my $groups  = $ldap->get_scot_groups($user);

    $self->session(
        user    => $user,
        groups  => $groups,
    );
    return 1;
}


sub update_user_sucess {
    my $self    = shift;
    my $user    = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    $log->debug("updating user $user sucess");

    # see if user record exists
    my $uobj    = $mongo->read_one_document({
        collection  => "users",
        match_ref   => { username => $user },
    });

    if ( defined($uobj) ) {
        $log->debug("User is defined");
        $uobj->attempts(0);
        $uobj->lockouts(0);
        $uobj->lastvisit($self->env->now);
        $mongo->update_document($uobj);
    }
    else {
        # this path only should occur when ldap auth works
        # but no local db entry for the user exists
        $self->env->log->error("New user $user not in database");
        $uobj   = Scot::Model::User->new({
            username    => $user,
            lastvisit   => $self->env->now(),
            theme       => "default",
            flair       => "on",
            display_orientation => "horizontal",
	    attempts	=> 0,
        });
        $mongo->create_document($uobj);
        $self->env->log->error("Now user $user is in database");
    }
}

sub local_authenticates {
    my $self    = shift;
    my $user    = shift;
    my $pass    = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    my $uobj    = $mongo->read_one_document({
        collection  => "users",
        match_ref   => { username => $user },
    });

    return 0 unless defined($uobj);

    $log->debug("User is in database");

    my $phash = $uobj->hash;

    return 0 unless defined($phash);
    return 0 if ($phash eq '');

    $log->debug("and has a hash of $phash");

    my $pbkdf2  = Crypt::PBKDF2->new(
        hash_class  => 'HMACSHA2',
        hash_args   => { sha_size => 512 },
        iterations  => 10000,
        salt_len    => 15,
    );

    return 0 unless ( $pbkdf2->validate($phash, $pass) );
    $log->debug("and its valid");
    return 0 unless ( $uobj->active );
    $log->debug("and user is active");

    my $groups  = $uobj->groups;
    $log->debug("setting groups to ".join(',',$groups));
    $self->session(
        user    => $user,
        groups  => $groups,
    );
    return 1;
}

sub update_user_failure {
    my $self    = shift;
    my $user    = shift;
    my $mongo   = $self->env->mongo;

    # see if user record exists
    my $uobj    = $mongo->read_one_document({
        collection  => "users",
        match_ref   => { username => $user },
    });

    if ( defined($uobj) ) {
        $uobj->attempts($uobj->attempts + 1);
        if ( $uobj->attempts == 11 ) {
            $uobj->lockouts($uobj->lockouts + 1);
        }
        $uobj->last_login_attempt($self->env->now);
        $mongo->update_document($uobj);
        $self->respond_401;
    }
    else {
        $self->env->log->error("Unknown user $user failed attempted authentication");
        $self->respond_401;
    }
}

sub respond_401 {
    my $self    = shift;
    $self->res->headers->www_authenticate('Basic realm="SCOT"');
    $self->respond_to(
        any => {
            json    => { error => "Invalid authentication token" },
            status  => 401,
        }
    );
}

sub not_trying_to_auth {
    my $self    = shift;
    my $auth    = shift;
    my $json    = shift;

    return undef if ( defined($auth) );
    return undef if ( defined($json) and defined($json->{'user'}));
    $self->env->log->error("No credentials sent, requesting them....");
    $self->respond_401;
    return 1;
}

sub get_user_pass {
    my $self    = shift;
    my $auth    = shift;
    my $json    = shift;
    my $user    = '';
    my $pass    = '';
    if ( defined($auth) ) {
        $auth      = decode_base64((split(/ /,$auth))[1]);
        ($user, $pass)  = split(/:/, $auth);
    }
    else {
        $user   = $json->{"user"};
        $pass   = $json->{"pass"};
    }
    $self->env->log->debug("We have user $user password");
    return $user, $pass;
}


sub has_invalid_user_chars {
    my $self    = shift;
    my $user    = shift;
    unless ( $user =~ m/^[a-zA-Z0-9_]+$/ ) {
        $self->env->log->error("Invalid username chars detected! $user");
        $self->respond_401;
        return 1;
    }
    return undef;
}

sub is_test_mode {
    my $self        = shift;
    my $env         = $self->env;
    my $mode        = $env->{mode};
    my $authmode    = $env->config->{$mode}->{authmode};

    $env->log->debug("Mode is $mode AUTHMODE is $authmode");

    if ($authmode eq "test" ) {
        $env->log->debug("TEST MODE : user is scot-test");
        my $groups  = $env->config->{development}->{test_groups};
        $self->session(
            user    => "scot-test",
            groups  => $groups,
            tz      => "MST7MDT",
        );
        return 1;
    }
    return undef;
}
1;
