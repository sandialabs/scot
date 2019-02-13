package Scot::Factory::Mongo;

use Meerkat;
use Data::Dumper;

use Moose;
extends qw(Scot::Factory);

sub make {
    my $self    = shift;
    my $config  = shift;
    return $self->get_mongo($config);
}

has product => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'Meerkat',
);

    
sub get_mongo {
    my $self    = shift;
    my $config  = shift;

    my $dbname       = $self->get_config_value( "db_name",      $config );
    my $host         = $self->get_config_value( "host",         $config );
    my $write_safety = $self->get_config_value( "write_safety", $config );
    my $find_master  = $self->get_config_value( "find_master",  $config );

    my $meerkat = Meerkat->new(
        model_namespace         => 'Scot::Model',
        collection_namespace    => 'Scot::Collection',
        database_name           => $dbname,
        client_options          => {
            host        => $host,
            w           => $write_safety,
            find_master => $find_master,
            socket_timeout_ms => 600000,
        },
    );

    return $meerkat;
}

1;
