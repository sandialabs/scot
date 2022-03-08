%environment = (
    model_namespace         => 'Scot::Model',
    collection_namespace    => 'Scot::Collection',
    database_name           => $self->dbname,
    client_options          => {
        host        => 'mongodb://localhost',
        w           => 1,
        find_master => 1,
        socket_timeout_ms => 600000,
    },
);
