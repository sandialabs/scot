package Scot::Util::Auth::RemoteUser;

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

=head1 RemoteUser

this authentication module respects the REMOTE_USER header
This allows us to work with sso systems and mod_ssl CA client auth
relies on basic auth and apache to do the heavy lifting

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

    $log->warn("no current scot session...");

    my $req     = $self->req;
    $user       = $req->headers->header('authuser');

    if ( defined $user ) {
        $log->warn("[User $user] Webserver authenticated $user" );
        # TODO: set other things like group membership from elsewhere
        # (ldap, local, ???)
        # if not in the proper group send an undef and and redirect like below
        return 1;
    }
    $self->redirect_to('unauthorized');
    return undef;
}

=item B<login>

this is kind of like an appendix when using basic auth

=cut

sub login {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = $self->session('orig_url');

    if ( $self->cehck ) {
        $self->redirect_to($url);
    }
    else {
        $self->redirect_to('unauthorized');
    }
}

=item B<logout>

This concept doesn't really exist in Basic Auth, unfortunately

=cut

sub logout {
    my $self    = shift;
}


1;
