package Scot::Util::Mongo;

use Meerkat;

sub new {
    my $class   = shift;
    my $config  = shift; # href of config items

    my $mongo   = Meerkat->new(
        model_namespace         => 'Scot::Model',
        collection_namespace    => 'Scot::Collection',
        database_name           => $config->{db_name},
        client_options          => {
            host        => $config->{host},
            w           => $config->{write_safety},
            find_master => $config->{find_master},
        },
    );

    return $mongo;
}

1;
