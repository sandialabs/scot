%environment = (
    log_config => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.test.log',
        log_level       => 'DEBUG',
    },
    time_zone   => 'America/Denver',
    default_owner   => 'scot-admin',
    default_groups  => {
        read    => ['wg-scot-ir'],
        modify  => ['wg-scot-ir'],
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
);
