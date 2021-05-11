%environment = (
    location    => 'snl',
    fetch_mode  => 'mongo',
    max_workers => 1,
    log_config => {
        logger_name => 'enricher_test',
        layout      => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name => 'enricher_log',
        logfile     => '/var/log/scot/test.log',
        log_level   => 'DEBUG',
    },
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

    blocklist_host  => 'b.foo.com',
    blocklist_user  => 'foo',
    blocklist_pass  => 'bar',

    enricher_mapping => {
        ipaddr  => [qw(geoip splunk robtex_ip)],
        ipv6    => [qw(geoip splunk rbotex_ip)],
        email   => [qw( )],
        md5     => [qw( )],
        sha1    => [qw( )],
        sha256  => [qw( )],
        domain  => [qw( )],
        file    => [qw( )],
        ganalytics   => [qw( )],
        snumber => [qw( )],
        lb_scan_id => [qw( )],
        uuid1   => [qw( )],
        message_id  => [qw( )],
        cve         => [qw( )],
    },
    enrichers => {
        splunk  => {
            type    => 'internal_link',
            url     => 'https://splunkist.watermellon.gov/searc?q=search%20%s',
            field   => 'value',
            title   => 'search on splunk',
        },
        robtex_ip => {
            type    => 'external_link',
            url     => 'https://www.robtex.com/ip/%s.html',
            field   => 'value',
            title   => 'Lookup on Robtex (external)',
        },
        geoip   => {
            type    => 'native',
            module  => 'Scot::Enricher::Entrichment::Geoip',
        },
    },
);
