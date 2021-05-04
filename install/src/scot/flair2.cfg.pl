%environment = (
    location    => 'snl',
    fetch_mode  => 'mongo',
    mozilla_public_suffix_file => '/opt/scot/etc/public_suffix_list.dat',
    log_config => {
        logger_name => 'regex_test',
        layout      => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name => 'regex_log',
        logfile     => '/var/log/scot/flair2.log',
        log_level   => 'DEBUG',
    },
    modules => [
        {
            attr    => 'mongo',
            class   => 'Scot::Util::MongoFactory',
            config  => {
                db_name         => 'scot-prod',
                host            => 'mongodb://localhost',
                write_safety    => 1,
                find_master     => 1,
            },
        },
    ],
    local_regexes => [
    ],
);
