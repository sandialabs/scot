%environment = (
    log_config  => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.backup.log',
        log_level       => 'DEBUG',
    },
    # modules used by backup app
    modules => [
    ],
    dbname      => 'scot-prod',
    pidfile     => '/var/run/scot/backup.pid',
    location    => '/opt/scotbackup/mongo',
    cacheimg    => '/opt/scotbackup/cached_images',
    tarloc      => '/opt/scotbackup/scotback',
    cleanup     => 1,
    es_server   => 'localhost:9200',
    es_backup_location  => '/opt/scotbackup/elastic',
    auth        => {
        # user => "username", # if needed
        # pass => "password", # ditto
    },
);
