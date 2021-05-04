%environment = (
    location    => 'snl',
    fetch_mode  => 'mongo',
    mozilla_public_suffix_file => '/opt/scot/etc/public_suffix_list.dat',
    log_config => {
        logger_name => 'regex_test',
        layout      => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name => 'regex_log',
        logfile     => '/var/log/scot/test.log',
        log_level   => 'DEBUG',
    },
    default_groups  => {
        read => ['wg-scot-ir'],
        modify => ['wg-scot-ir'],
    },
    default_owner   => 'scot-admin',
    modules => [
        {
            attr    => 'mongo',
            class   => 'Scot::Util::MongoFactory',
            config  => {
                db_name         => 'scot-test',
                host            => 'mongodb://localhost',
                write_safety    => 1,
                find_master     => 1,
            },
        },
    ],
    local_regexes => [
        {
            type    => 'snumber',
            regex   => '\b([sS][0-9]{6,7})\b',
            order   => 500,
            options => { multiword => "no" },
        },
        {
            type    => 'sandia_server',
            regex   => '\bas[0-9]+snl(lx|nt)\b',
            order   => 500,
            options => { multiword => "no" },
        },
    ],
);
