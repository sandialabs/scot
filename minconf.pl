%environment = (
    # where to find chef
    chef_uri                => 'https://cybertools-cc.sandia.gov',
    # what to put at the top
    classification_banner   => 'OUO',
    location                => 'snl',

    row_limit           => 100,
    session_expiration  => 3600 * 4,

    time_zone   => 'America/Denver',
    mode        => 'prod',  # or 'dev'
    auth_type   => 'Remoteuser',
    group_mod   => 'ldap',

    default_owner   => 'scot-admin',
    default_groups  => {
        read        => [ 'wg-scot-ir', 'wg-scot-researchers' ],
        modify      => [ 'wg-scot-ir' ],
    },

    admin_group => 'wg-scot-admin',

    file_store_root => '/opt/scotfiles',

    mojo_defaults   => {
        secrets             => [qw(scot1sfun sc0t1sc00l)],
        default_expiration  => 14400,
        hypnotoad           => {
            listen      => [ 'http://localhost:3000?reuse=1' ],
            workers     => 75,
            clients     => 1,
            proxy       => 1,
            pidfile     => '/var/run/hypno.pid',
            heartbeat_timeout   => 40,
        }
    },
    secrets_location    => '/opt/scot/etc/secrets',


);
