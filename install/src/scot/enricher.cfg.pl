%environment = (
    location    => 'snl',
    fetch_mode  => 'mongo',
    max_workers => 5,
    log_config => {
        logger_name => 'enricher',
        layout      => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name => 'enricher_log',
        logfile     => '/var/log/scot/enricher.log',
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
        {
            attr    => 'mq',
            class   => 'Scot::Util::Messageq',
            config  => {
                destination => 'scot',
                stomp_host  => 'localhost',
                stomp_port  => 61613,
            },
        },
    ],

# enrichers
# key = the lc version of the Scot::Enricher::Enrichment::* 
# href = the configuration data for the enrichment
# only required element:
# enrichables = the entity types that will have this enrichment applied to

    enrichers => {
        binip   => {
            field   => 'value',
            enrichables => [ qw(ipaddr) ],
        },
        robtex_ip => {
            url     => 'https://www.robtex.com/ip/%s.html',
            field   => 'value',
            title   => 'Lookup on Robtex (external)',
            enrichables => [qw(ipaddr ipv6)],
        },
        robtex_dns   => {
            url     => 'https://www.robtex.com/dns/%s.html',
            field   => 'value',
            title   => 'Lookup on Robtex (external)',
            enrichables => [qw(domain)],
        },
        geoip   => {
            enrichables => [qw(ipaddr ipv6)],
        },
        splunk      => {
            url     => 'https://splunk_host.yourdomain.tld/en-US/app/search/search?q=search%%20%s',
            field   => 'value',
            title   => 'Search on Splunk',
            enrichables => [qw(
                ipaddr ipv6 email md5 sha1 sha256 domain file ganalytics
                snumber lb_scan_id uuid1 message_id cve
            )],
        },
        virustotal  => {
            url     => 'https://www.virustotal.com/gui/search/%s',
            field   => 'value',
            title   => 'Search on VirusTotal',
            enrichables => [qw(md5 sha1 sha256)],
        },
        recfutureproxy  => {
            url     => "/scot/api/v2/recfuture/%s",
            field   => "id",
            title   => "Query Recorded Future API",
            nopopup => 1,
            enrichables => [qw(ipaddr ipv6 md5 sha1 sha256 domain)],
        },
    },
);
