package Scot::Util::Aaa;

use lib '../../../lib';
use v5.18;
use strict;
use warnings;

use MIME::Base64;
use Net::LDAP;
use Digest::SHA qw(sha512_hex);
use Crypt::PBKDF2;
use Scot::Model::User;

use base 'Mojolicious::Controller';

=item B<check>

Get called on every route under /scot
Does only one thing: Check for the presence of the 
the user variable in the session cookie.
That is only set if user has authenticated.

=cut

sub check {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $user    = $self->session('user');
    
    $log->trace("Checking Login Status");

    if (defined $user) {
        # TODO: update last use records for user
        $log->trace("[User $user] has logged in");
        return 1;
    }

    # if testing, do away with pesky auth
    if ($ENV{'scot_mode'} eq "testing") {
        $log->warn('SCOT is in INSECURE testing mode!');
        $self->session(
            user        => "test",
            groups      => [qw(ir testing)],
            secure      => 1,
            expiration  => 3600 * 4,
        );
        return 1;
    }

    $log->trace("Not in testing mode");

    my $req     = $self->req;
    my $url     = $req->url->to_string();
    $log->trace("Login Form will redirect after auth to url = $url");
    $self->session(orig_url => $url);


    $self->redirect_to('/login');
    return 0;
}

=item B<login>

This will render the login in page

=cut

sub login {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = $self->session('orig_url');
    $log->trace("Trying to render Login Form url = $url");
    $self->render( orig_url => $url );
}

=item B<logout>

You can now expire you session cookie!
Log out has been achieved

=cut

sub logout {
    my $self    = shift;
    $self->session(expires => 1);
    $self->redirect_to('/login');
}

=item B<auth>

this gets called by posting the form rendered in the login method
if you auth, you get a session cookie
if not, no scot for you

=cut

# need to put some rate limiter in here and or lock outs

sub auth {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $path    = $self->req->url->path;

    $log->trace("Authentication Check Begins");

    my $user    = $self->param('user');
    my $pass    = $self->param('pass');
    my $orig_url= $self->param('orig_url');

    $log->trace("Got user = $user orig_url = $orig_url");

    unless ( defined $user and defined $pass ) {
        return $self->failed_auth(
            "Undefined user or pass",
            $user, 
            $pass);

    }

    if ( $self->is_test_mode ) {
        $log->trace("TEST MODE");
        $self->session(
            user        => $env->test_user,
            groups      => $env->test_groups,
            secure      => 1,
            expiration  => 3600 * 4,
        );
        return;
    }

    if ( $self->has_invalid_user_chars($user) ) {
        return $self->failed_auth("Invalid chars in username", $user);
    }

    if ( length($pass) > 32 or length($user) > 32) {
        return $self->failed_auth(
            "Pass or User was longer than 32 chars",
            $user, 
            $pass);
    }

    if ( defined( $self->env->ldap ) ) {
        $log->trace("attempting ldap auth for user $user");
        if ( $self->ldap_authenticates($user, $pass) ) {
            return $self->sucessful_auth($user, $orig_url);;
        }
        else {
            # not returning here because LDAP could fail
            # on a local only account, so you get one more shot
            $log->error("Failed LDAP AUTH, will attempt Local Auth");
        }
    }

    $log->trace("Attempting local authentication for $user");
    if ( $self->local_authenticates($user, $pass) ) {
        return $self->sucessful_auth($user);
    }

    return $self->failed_auth(
        "ALL attempts to authenticate $user failed",
        $user,
        $pass);
}

sub failed_auth {
    my $self    = shift;
    my $msg     = shift;
    my $user    = shift;
    my $pass    = shift;
    my $log     = $self->env->log;

    $log->error("FAILED AUTH: $msg");
    $log->debug("User: $user Pass: -----");

    $self->flash("Invalid Login");
    $self->redirect_to('/login');
    return;
}

sub sucessful_auth {
    my $self    = shift;
    my $user    = shift;
    my $url     = shift;
    my $log     = $self->env->log;

    $log->debug("User $user sucessfully authenticated");

    $self->update_user_sucess($user);
    $self->session( 
        user        => $user, 
        groups      => $self->get_user_groups($user),
        secure      => 1,
        expiration  => 3600 * 4,
    );

    $self->redirect_to($url); 
    return;
}

sub get_user_groups {
    my $self    = shift;
    my $user    = shift;
    my $env     = $self->env;

    if ( $env->ldap ) {
        return $env->ldap->get_users_groups($user);
    }
    else {
        my $mongo       = $env->mongo;
        my $collection  = $mongo->collection('User');
        my $user        = $collection->find_one(username => $user);
        return $user->groups;
    }
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

#    unless ($ldap->is_configured) {
#        $log->error("LDAP not configured!");
#        return 0;
#    }

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

sub local_authenticates {
    my $self        = shift;
    my $username    = shift;
    my $pass        = shift;
    my $mongo       =  $self->env->mongo;
    my $log         =  $self->env->log;

    $log->trace("Local Authentication for $username");

    my $collection  = $mongo->collection('User');
    my $user        = $collection->find_one({ username => $username });

    return 0 unless defined($user);

    $log->trace("User is in Database...");

    my $phash   = $user->hash;

    return 0 unless defined($phash);
    return 0 if ($phash eq '');

    $log->trace('User has a password hash...');

    my $pbkdf2  = Crypt::PBKDF2->new(
        hash_class  => 'HMACSHA2',
        hash_args   => { sha_size   => 512 },
        iterationss => 10000,
        salt_len    => 15,
    );

    return 0 unless ( $pbkdf2->validate($phash, $pass) );

    $log->trace("Password matches Hash...");

    return 0 unless ( $user->active );

    $log->trace("user $user is active...");

    my $groups  = $user->groups;

    $self->session(
        user    => $user,
        groups  => $groups,
    );
    return 1;
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
    my $mode        = $env->mode;
    my $authmode    = $env->authmode;

    $env->log->debug("Mode is $mode AUTHMODE is $authmode");

    if ($authmode eq "test" ) {
        $env->log->debug("TEST MODE : user is scot-test");
        my $groups  = $env->get_test_groups();
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
