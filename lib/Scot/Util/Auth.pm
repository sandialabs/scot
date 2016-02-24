package Scot::Util::Auth;

use lib '../../../lib';
use v5.18;
use strict;
use warnings;

=head1 Scot::Util::Auth

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

sub update_user_sucess {
    my $self    = shift;
    my $user    = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    $log->trace("Updating User $user Authentication Sucess");

    my $collection  = $mongo->collection("User");
    my $userobj     = $collection->find_one({username => $user});

    if ( defined $userobj ) { 
        $log->trace("User object $user retrieved");
        $userobj->update_set( attempts => 0);
        $userobj->update_set( lockouts => 0);
        $userobj->update_set( lastvisit=> $self->env->now);
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

1;
