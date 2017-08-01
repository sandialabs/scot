%environment = (
    time_zone   => 'America/Denver',
    log_config  => {
        logger_name     => 'SCOT_REPLICATE',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.relplicate.log',
        log_level       => 'DEBUG',
    },
    modules => [
        {
            attr    => 'source',
            class   => 'Scot::Util::Scot2',
            config  => {
                servername  => 'localhost',
                # username with sufficient scot perms to create alert(groups)
                username    => 'scot-alerts',
                # the password for that user
                password    => 'changemenow',
                # authentication type: RemoteUser, LDAP, Local
                authtype    => 'Local',
            },
        },
        {
            attr    => 'dest',
            class   => 'Scot::Util::Scot2',
            config  => {
                servername  => 'not_localhost',
                # username with sufficient scot perms to create alert(groups)
                username    => 'scot-alerts',
                # the password for that user
                password    => 'changemenow',
                # authentication type: RemoteUser, LDAP, Local
                authtype    => 'Local',
            },
        },
    ],
);
