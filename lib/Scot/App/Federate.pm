package Scot::App::Federate;

use lib '../../../lib';
use lib '/opt/scot/lib';

=head1 Name

Scot::App::Federate

=head1 Description

Enable the Federation functions for SCOT to SCOT federation

=cut

use Data::Dumper;
use Try::Tiny;
use Scot::Env;
use Scot::App;
use AnyEvent::STOMP::Client;
use AnyEvent::ForkManager;
use strict;
use warnings;
use v5.18;
use Moose;
extends 'Scot::App';

=head2 Attributes

=over 4

=item B<upstream>

This is the hostname of the SCOT instances that is "above" this instance
Typically, you have one upstream, but why limit ourselves?

=cut

has upstreams => (
    is          => 'ro',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    required    => 1,
    builder     => '_get_upstream',
);

sub _get_upstream {
    my $self            = shift;
    my $server_env_var  = $ENV{'scot_upstream_servers'};
    my @servers         = ();

    if (defined $server_env_var) {
        @servers   = split(/:/,$server_env_var);
    }
    else {
        my $env     = Scot::Env->instance;
        @servers    = @{$env->upstream_servers};
    }
    return wantarray ? @servers : \@servers;
}

=item B<downstreams>

This is the hostname of the SCOT instances that is "below" this instance

=cut

has downstreams => (
    is          => 'ro',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    required    => 1,
    builder     => '_get_upstream',
);

sub _get_downstream {
    my $self            = shift;
    my $server_env_var  = $ENV{'scot_downstream_servers'};
    my @servers         = ();

    if (defined $server_env_var) {
        @servers   = split(/:/,$server_env_var);
    }
    else {
        my $env     = Scot::Env->instance;
        @servers    = @{$env->downstream_servers};
    }
    return wantarray ? @servers : \@servers;
}


