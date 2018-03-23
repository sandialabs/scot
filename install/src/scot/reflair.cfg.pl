%environment = (
    time_zone   => 'America/Denver',
    # server name of the SCOT server
    servername  => 'localhost',
    # username with sufficient scot perms to create alert(groups)
    username    => 'scot-alerts',
    # the password for that user
    password    => 'changemenow',
    # authentication type: RemoteUser, LDAP, Local
    authtype    => 'Local',
    # interactive
    interactive => 0,
    # max workers
    max_workers => 20,
    # log config
    log_config  => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.flair.log',
        log_level       => 'DEBUG',
    },
    stomp_host  => "localhost",
    stomp_port  => 61613,
    topic       => "/topic/scot",
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
        {
            attr    => 'es',
            class   => 'Scot::Util::ElasticSearch',
            config  => {
                nodes       => [ qw(localhost:9200) ],
                max_workers => 1,
            },
        },
    ],
    # future use:
    location                => "scot_demo",
    site_identifier         => "scot_demo",
    default_share_policy    => "none",
);
