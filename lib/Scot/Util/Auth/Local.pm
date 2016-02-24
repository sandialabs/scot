package Scot::Util::Auth::Local;

use lib '../../../../lib';
use v5.18;
use strict;
use warnings;

use MIME::Base64;
use Net::LDAP;
use Digest::SHA qw(sha512_hex);
use Crypt::PBKDF2;
use Scot::Model::User;

use base 'Scot::Util::Auth';

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


    $log->trace("New or expired session...");

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

    $user   = lc($user);
    $pass  =~ s/^\s+(\w+)\s+$/$1/;

    if ( $self->has_invalid_user_chars($user) ) {
        return $self->failed_auth("Invalid chars in username", $user);
    }

    if ( length($pass) > 32 or length($user) > 32) {
        return $self->failed_auth(
            "Pass or User was longer than 32 chars",
            $user, 
            $pass);
    }

    $log->trace("Attempting local authentication for $user");
    if ( $self->local_authenticates($user, $pass) ) {
        return $self->sucessful_auth($user);
    }

    return $self->failed_auth(
        "Local attempt to authenticate $user failed",
        $user,
        $pass);
}

sub get_user_groups {
    my $self        = shift;
    my $user        = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $collection  = $mongo->collection('User');
    my $userobj     = $collection->find_one(username => $user);
    return $userobj->groups;
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


1;
