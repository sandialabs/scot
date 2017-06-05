%environment = (
    servername  => 'as3002snllx',
    serverport  => 443,
    username    => 'scot-alerts',
    password    => 'xxxxx',
    http_method => 'https',
    auth_type   => 'basic',
    log_config  => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.client.log',
        log_level       => 'DEBUG',
    },
);
