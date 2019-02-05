package Scot::Factory::Stomp;

use strict;
use warnings;
use lib '../../lib';

use AnyEvent::STOMP::Client;
use Moose;

extends qw(Scot::Factory);

=item b<make>

sub to call to make factory 
produce target object

=cut

sub make {
    my $self    = shift;
    my $config  = shift;
    return $self->get_stomp($config);
}

has product => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'AnyEvent::STOMP::Client',
);


sub get_stomp {
    my $self     = shift;
    my $config   = shift;
    my $attempts = 0;

    my $host = $self->get_config_value( "host",        $config );
    my $port = $self->get_config_value( "port",        $config );
    my $dest = $self->get_config_value( "destination", $config );

    my $stomp = AnyEvent::STOMP::Client->new( $host, $port, );
    $stomp->connect();
    $stomp->on_connected(
        sub {
            my $client = shift;
            $client->subscribe($dest);
        }
    );
    $stomp->on_connect_error(
        sub {
            my $client = shift;
            sleep 10;
            $attempts++;
            if ( $attempts > 3 ) {
                die "Can not connect to $host:$port via stomp";
            }
            $stomp->connect();
        }
    );
    return $stomp;
}

1;
