package Scot::Controller::Auth::Testing;

use lib '../../../../lib';
use v5.18;
use strict;
use warnings;

use MIME::Base64;
use Net::LDAP;
use Digest::SHA qw(sha512_hex);
use Crypt::PBKDF2;
use Scot::Model::User;

use base 'Scot::Controller::Auth';

=head1 Testing

WARNING! only use this module if you want no Authentication at all.
Should only be used for testing.

=cut

sub check {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
#    my $mongo   = $env->mongo;
    my $user    = $self->session('user');
    
    $log->trace("Checking Login Status");

    if (defined $user) {
        # TODO: update last use records for user
        $log->trace("[User $user] has logged in");
        return 1;
    }

    $log->warn("no current scot session...");

    my $req     = $self->req;
    $user       = "scot-testing";

    if ( defined $user ) {
        $log->warn("[User $user] TESTING (non)authenticated $user" );
        $self->session(groups => $env->default_groups->{modify});
        $self->session(user => $user, secure => 1, expiration => 600);
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
