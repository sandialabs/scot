package Scot::Controller::Auth;

use lib '../../../lib';
use v5.18;
use strict;
use warnings;

use base 'Mojolicious::Controller';

=head1 Scot::Controller::Auth

superclass of auth modules
common functions here
the configuration as startup will 
define the auth module used

=cut

sub has_invalid_user_chars {
    my $self    = shift;
    my $user    = shift;
    # help prevent ldap injection
    unless ( $user =~ m/^[a-zA-Z0-9_@]+$/ ) {
        $self->env->log->error("Invalid username chars detected! $user");
        $self->respond_401;
        return 1;
    }
    return undef;
}

sub update_lastvisit {
    my $self    = shift;
    my $user    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    $log->trace("[User $user] update lastvisit time");

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
        eval {
            $userobj    = $collection->create(
                username    => $user,
                lastvisit   => $self->env->now,
                theme       => 'default',
                flair       => 'on',
                display_orientation => 'horizontal',
                attempts    => 0,
            );
        };
        if ($@) {
            $log->error("Failed to create User $user! $@");
        }
    }
}

sub update_user_failure {
    my $self        = shift;
    my $username    = shift;
    my $mongo       = $self->env->mongo;
    my $log         = $self->env->log;

    $log->trace("Updating User $username failure to authenticate");

    my $collection  = $mongo->collection('User');
    my $user        = $collection->find_one(username    => $username);

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

sub check_for_csrf {
    my $self    = shift;
    # see: https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)_Prevention_Cheat_Sheet
    # for now, choosing the Custom Request Header check for it's friendliness to REST

    return 1;  #for testing...

    my $headers = $self->req->headers;
    my $reqwith = $headers->header('X-Requested-With');
    my $log     = $self->env->log;

    $log->debug("CSRF Check...");

    my $url = $self->req->url->to_abs;

    $log->debug("URL is $url");

    unless ( $url =~ /\/scot\/api\// ) {
        $log->warn("Not a REST request, skipping CSRF check...");
        return 1;
    }

    if ( $reqwith eq "XMLHttpRequest" ) {
        $log->debug("Passed CSRF Check");
        return 1;
    }
    $log->error("Invalid Content of header X-Requested-With: ".$reqwith);
    return undef;
}

1;
