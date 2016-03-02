package Scot::Controller::Auth::Remoteuser;

use lib '../../../../lib';
use v5.18;
use strict;
use warnings;

use MIME::Base64;
use Net::LDAP;
use Digest::SHA qw(sha512_hex);
use Crypt::PBKDF2;
use Scot::Model::User;
use Data::Dumper;

use base 'Scot::Controller::Auth';

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

    $log->debug("Authentication check begins");

    my $request     = $self->req;
    my $headers     = $request->headers;


    $log->debug("headers = ".Dumper($headers));

    my $basicauth   = $headers->header('authorization');
    my $authuser    = $headers->header('authuser');

    my $user    = $self->session('user');

    return 1 if (defined $user);  
    $log->debug("user not previously authenticated");

    my $remote_user = $headers->header('remote-user');

    $log->debug("Remote user is set to: ".$remote_user);

    if ( $remote_user ) {
        # can do look ups of user groups here
        $self->session( 'user'  => $remote_user );
        return 1;
    }

    return undef;
}

sub login {
    my $self    = shift;
    my $href    = { status => "fail" };
    if ( $self->check ) {
        $href->{status} = "ok";
    }
    $self->render( json => $href);
}



1;
