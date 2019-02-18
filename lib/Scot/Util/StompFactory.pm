package Scot::Util::StompFactory;

use strict;
use warnings;
use lib '../../lib';

use AnyEvent::STOMP::Client;
use Moose;

extends qw(Scot::Util);

=item b<host>

the hostname of the stomp server

=cut

has host    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_host',
);

sub _build_host {
    my $self    = shift;
    my $attr    = "host";
    my $default = "localhost";
    my $envname = "scot_util_stomp_host";
    return $self->get_config_value($attr, $default, $envname);
}

=item b<port>

the port the stomp server listens to

=cut

has port    => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_build_port',
);

sub _build_port {
    my $self    = shift;
    my $attr    = "port";
    my $default = 61613;
    my $envname = "scot_util_stomp_port";
    return $self->get_config_value($attr, $default, $envname);
}

has destination => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_destination',
);

sub _build_destination {
    my $self    = shift;
    my $attr    = "destination";
    my $default = "/topic/scot";    # /queue/x as alternative
    my $envname = "scot_util_stomp_dest";
    return $self->get_config_value($attr, $default, $envname);
}

sub get_stomp_client {
    my $self    = shift;
    my $host    = $self->host;
    my $port    = $self->port;
    my $dest    = $self->destination;
    my $log     = $self->env->log;
    my $stomp   = AnyEvent::STOMP::Client->new(
        $host,
        $port,
    );
    $stomp->connect();
    $stomp->on_connected( sub {
        my $client   = shift;
        $client->subscribe($self->destination);
        $log->debug("subscribed to $host:$port $dest");
    });
    $stomp->on_connect_error( sub {
        my $client  = shift;
        $log->error("Error connecting to Stomp $host:$port.  Will retry in 10 seconds");
        sleep 10;
        $stomp->connect();
    });

    return $stomp;
}

1;
