%environment = (
    location    => 'snl',
    fetch_mode  => 'mongo',
    max_workers => 1,
    log_config => {
        logger_name => 'enricher',
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

# enrichers
# key = the lc version of the Scot::Enricher::Enrichment::* 
# href = the configuration data for the enrichment
# only required element:
# enrichables = the entity types that will have this enrichment applied to

    enrichers => {
#        blocklist   => {
#            servername  => 'blocklist.sandia.gov',
#            username    => 'scot-alerts',
#            password    => 'xxxxxxxxxx',
#            enrichables => [qw(
#                ipaddr ipv6 domain
#            )],
#        },
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
        hybrid_msgid     => {
            url     => "https://mds.gibson.sandia.gov/messageidmap/%s",
            field   => "value",
            title   => 'Lookup in Hybrid',
            enrichables => [qw(message_id)],
        },
        laikaboss     => {
            url     => "https://lb.sandia.gov/search/%s",
            field   => "value",
            title   => 'Lookup in Likaboss',
            enrichables => [qw(lb_scan_id uuid1)],
        },
        hybrid_docid     => {
            url     => "https://mds.gibson.sandia.gov/docmap/%s",
            field   => "value",
            title   => 'Lookup in Hybrid',
            enrichables => [qw(md5)],
        },
        splunk      => {
            url     => 'https://splunk.sandia.gov/en-US/app/search/search?q=search%%20%s',
            field   => 'value',
            title   => 'Search on Splunk',
            enrichables => [qw(
                ipaddr ipv6 email md5 sha1 sha256 domain file ganalytics
                snumber lb_scan_id uuid1 message_id cve
            )],
        },
        ick_ip      => {
            url     => 'https://ick.sandia.gov/ipaddress/details/%s',
            field   => 'value',
            title   => 'ICK IP Details',
            enrichables => [qw(ipaddr ipv6)],
        },
        ick_snumber => {
            url     => 'https://ick.sandia.gov/machine/details/%s',
            field   => 'value',
            title   => 'ICK S Number Details',
            enrichables => [qw(snumber)],
        },
        msgid_splunkdash => {
            url     => 'https://splunk.sandia.gov/en-US/app/search/messageid_detail  s?form.fn=MESSAGE_ID&form.fvalue=%s',
            field   => 'value',
            title   => 'Message ID Splunk Dashboard',
            enrichables => [qw(message_id)],
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
        lriproxy    => {
             url     => "/scot/api/v2/lriproxy/%s",
            field   => "id",
            title   => "Query LRI API",
            nopopup => 1,
            enrichables => [qw(ipaddr ipv6 md5 sha1 sha256 domain)],
        },
        cve_lookup  => {
            url     => "https://splunk.sandia.gov/en-US/app/TA_recordedfuture-cyber/recorded_future_vuln_enrichment?form.name=%s",
            field   => "value",
            title   => "Lookup CVE description",
            enrichables => [qw(cve)],
        },
        laikaboss   => {
            url     => "https://lb.sandia.gov/search/%s",
            field   => "value",
            title   => "Lookup in Laikaboss",
            enrichables => [qw(lb_scan_id uuid1)],
        },
        vmray       => {
            url     => "https://vmray.sandia.gov/user/submission/list?submission_field_1=tag&submission_operator_1===&submission_value_1=%s&submission_connector_1=",
            field   => "value",
            title   => "Lookup in VMRay",
            enrichables => [qw(lb_scan_id uuid1)],
        },
        memorialization => {
            url     => "https://lb.sandia.gov/api/post/memorialize/%s",
            field   => "value",
            title   => "Memorialize rootuid in Laikaboss",
            enrichables => [qw()],
        },
        asdf_snumber    => {
            url     => 'https://asdf.sandia.gov/?field=asset_number&query=%s',
            field   => 'value',
            title   => 'Search on asdf',
            enrichables => [qw(snumber)],
        },
        rf_ipaddr   => {
            url     => 'https://splunk.sandia.gov/en-US/app/TA_recordedfuture-cyber/recorded_future_ip_enrichment?form.name=%s',
            field   => 'value',
            title   => 'Recorded Future',
            enrichables => [qw(ipaddr ipv6)],
        },
        farm        => {
            url     => "https://farm.sandia.gov/search/?q=%s",
            field   => 'value',
            title   => 'Search Farm',
            enrichables => [qw(ipaddr ipv6 email md5 sha1 sha256 domain file)],
        },
    },
);
