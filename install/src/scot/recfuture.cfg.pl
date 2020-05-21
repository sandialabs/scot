%environment = (
    api_key => "your_key_goes_here",
    proxy => "proxy_url_here",
    location    => "snl",
    site_identifier    => "snl",
    time_zone   => 'America/Denver',
    # server name of the SCOT server
    servername  => 'localhost',
    # interactive
    interactive => 0,
    # max workers
    max_workers => 1,
    # log config
    log_config  => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/recfutureproxy.log',
        log_level       => 'DEBUG',
    },
    stomp_host  => "localhost",
    stomp_port  => 61613,
    topic       => '/queue/recfuture',
    # modules used by flair app
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
        {
            attr    => 'mq',
            class   => 'Scot::Util::Messageq',
            config  => {
                destination => "scot",
                stomp_host  => "localhost",
                stomp_port  => 61613,
            },
        },
    ],
);
