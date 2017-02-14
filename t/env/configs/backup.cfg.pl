%environment = (
    pidfile     => '/var/run/scot/backup.pid',
    location    => '/opt/scotbackup/mongo',
    tarloc      => '/opt/scotbackup/scotback',
    cleanup     => 1,
    es_server   => 'localhost:9200',
    es_backup_location  => '/opt/scotbackup/elastic',
    log_config  => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.flair.log',
        log_level       => 'DEBUG',
    },
    modules => [
    ],
);
