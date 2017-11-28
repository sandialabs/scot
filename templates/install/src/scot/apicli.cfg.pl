%environment    = (
    log_config  => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.apiicli.log',
        log_level       => 'DEBUG',
    },
    modules     => [
        {
            attr    => 'scot',
            class   => 'Scot::Util::Scot2',
            config  => {
                servername  => 'scotserver',
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
