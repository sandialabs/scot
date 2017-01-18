package Scot::Util::Mongo;

use Meerkat;
use Data::Dumper;

sub new {
    my $class   = shift;
    my $config  = shift; # href of config items
    my $c       = $config->{conf};

    my $mongo   = Meerkat->new(
        model_namespace         => 'Scot::Model',
        collection_namespace    => 'Scot::Collection',
        database_name           => $c->{db_name},
        client_options          => {
            host        => $c->{host},
            w           => $c->{write_safety},
            find_master => $c->{find_master},
        },
    );

    return $mongo;
}

1;
