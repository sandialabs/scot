package Scot::Controller::Auth;

use lib '../../../lib';
use v5.18;
use strict;
use warnings;

use base 'Mojolicious::Controller';

=head1 Scot::Controller::Auth

Authentication and Authorization 

=cut

=item B<login>

this route will generate a web based form for login

=cut

sub login {
    my $self    = shift;
    my $href    = { status => "fail" };
    if ( $self->check ) {
        $href->{status} = "ok";
    }
    $self->render( json => $href );
}

sub logout {
    my $self    = shift;
    $self->session( user    => '' );
    $self->session( groups  => '' );
    $self->session( expires => 1 );
}

=item B<check>

This sub gets called on every route under /scot.  This routine checks the authentication
status of the request.

    First, we look for a mojolicious session.  The presence of that indicates that 
    the use has been authenticated and we can return true.

    Second, we look for an API token.  If we find a valid one, then we are good.

    Finally, we either do a Local authentication or we redirect to an Apache Authentication
    landing that will do SSO for us.

=cut

sub check {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $request = $self->req;
    my $user    = '';
    
    $log->debug("Authentication Check Begins...");

    $log->debug("Checking Mojo Session");

    if ( $user = $self->valid_mojo_session ) {
        $log->debug("Successful Prior Authentication Still Valid");
        if ($self->set_group_membership($user)) {
            return 1;
        }
        else {
            return undef;
        }
    }

    my $headers = $request->headers;

    $log->debug("Checking Authorization Header");

    if ( $user = $self->valid_authorization_header($headers) ) {
        $log->debug("Successful Authentication via Authorization Header");
        $self->set_group_membership($user);
        return 1;
    }

    $log->debug("Checking Remoteuser set by Webserver");

    if ( $user = $self->valid_remoteuser($headers) ) {
        $log->debug("Successful Authentication via Remoteuser Header");
        if ( $self->set_group_membership($user) ) {
            return 1;
        }
        else {
            return undef;
        }
    }

    $log->error("Failed Authentication Check");
    return undef;
}

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

sub valid_authorization_header {
    my $self    = shift;
    my $headers = shift;
    my $log     = $self->env->log;
    my $user;

    my $auth_header     = $headers->header('authorization');
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
    return undef;
}

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

    $log->debug("Group Membership");

    my $groups  = $self->session('groups');
    if ( ref($groups) eq "ARRAY" ) {
        $log->debug("Groups set in Mojo Session");
        $log->debug("$user Groups are ".join(', ',@$groups));
        return 1;
    }

    $log->debug("Group membership not in session, fetching...");
    $groups = $self->get_groups($user);

    if ( scalar(@$groups) > 0 ) {
        $log->debug("Got 1 or more groups, storing in session");
        $self->session(groups => $groups);
        return 1;
    }
    else {
        $log->error("User has null group set!");
        return undef;
    }
}

sub get_groups {
    my $self    = shift;
    my $user    = shift;
    my $log     = $self->env->log;
    my $mode    = $self->env->group_mode;
    my @groups  = ();
    my $results;

    $log->debug("Getting groups for user $user with mode $mode");

    if ( $mode =~ /ldap/i ) {
        my $ldap = $self->env->ldap;

        if ( defined $ldap ) {
            $results = $ldap->get_users_groups($user);
            if ( $results < 0 ) { # TODO: refactor to check for empty array?
                $log->error("LDAP group ERROR!");
            }
        }
    }
    else {
        my $mongo   = $self->env->mongo;
        my $ucol    = $mongo->collection("User");
        my $user    = $ucol->find_one({username => $user});

        if ( defined $user ) {
            $results    = $user->groups;
        }
        else {
            $log->error("User $user, not in local user collection!");
        }
    }

    push @groups, grep {/scot/i} @$results;
    return wantarray ? @groups : \@groups;
}


sub has_invalid_user_chars {
    my $self    = shift;
    my $user    = shift;
    # help prevent ldap injection
    unless ( $user =~ m/^[a-zA-Z0-9_@=]+$/ ) {
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
