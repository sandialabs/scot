%environment = (
    # server name of the SCOT server
    servername  => 'as3001snllx',
    # username with sufficient scot perms to create alert(groups)
    username    => 'scot-alerts',
    # the password for that user
    password    => 'ukeSb=r9',
    # authentication type: RemoteUser, LDAP, Local
    authtype    => 'RemoteUser',
    # log config
    log_config  => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.flair.log',
        log_level       => 'DEBUG',
    },
    # modules used by flair app
    modules => [
        {
            attr    => 'enrichments',
            class   => 'Scot::Util::Enrichments',
            config  => {
                # mappings map the enrichments that are available 
                # for a entity type
                mappings    => {
                    ipaddr      => [ qw(splunk ick_ip geoip robtex_ip sidd) ],
                    email       => [ qw(splunk ) ],
                    md5         => [ qw(splunk hybrid_docid ) ],
                    sha1        => [ qw(splunk ) ],
                    sha256      => [ qw(splunk ) ],
                    domain      => [ qw(splunk robtex_dns sidd ) ],
                    file        => [ qw(splunk  ) ],
                    ganalytics  => [ qw(splunk  ) ],
                    snumber     => [ qw(splunk ick_snumber  ) ],
                    message_id  => [ qw(splunk hybrid_msgid) ],
                },

                # foreach enrichment listed above place any 
                # config info for it here
                configs => {
                    sidd    => {
                        type    => 'native',
                        module  => 'Scot::Util::Sidd',
                        config  => {
                            servername  => 'sidd.sandia.gov',
                            username    => 'scot',
                            password    => '3mIn8g$doliq*7qIS-suopu88',
                        }
                    },
                    geoip   => {
                        type    => 'native',
                        module  => 'Scot::Util::Geoip',
                    },
                    hybrid_msgid     => {
                        type    => 'internal_link',
                        url     => "https://mds.gibson.sandia.gov/messageidmap/%s",
                        field   => "value",
                        title   => 'Lookup in Hybrid',
                    },
                    hybrid_docid     => {
                        type    => 'internal_link',
                        url     => "https://mds.gibson.sandia.gov/docmap/%s",
                        field   => "value",
                        title   => 'Lookup in Hybrid',
                    },
                    robtex_ip   => {
                        type    => 'external_link',
                        url     => 'https://www.robtex.com/ip/%s.html',
                        field   => 'value',
                        title   => 'Lookup on Robtex (external)',
                    },
                    robtex_dns   => {
                        type    => 'external_link',
                        url     => 'https://www.robtex.com/dns/%s.html',
                        field   => 'value',
                        title   => 'Lookup on Robtex (external)',
                    },
                    splunk      => {
                        type    => 'internal_link',
                        url     => 'https://splunk.sandia.gov/en-US/app/search/search?q=search%%20%s',
                        field   => 'value',
                        title   => 'Search on Splunk',
                    },
                    ick_ip      => {
                        type    => 'internal_link',
                        url     => 'https://ick.sandia.gov/ipaddress/details/%s',
                        field   => 'value',
                        title   => 'ICK IP Details',
                    },
                    ick_snumber => {
                        type    => 'internal_link',
                        url     => 'https://ick.sandia.gov/machine/details/%s',
                        field   => 'value',
                        title   => 'ICK S Number Details',
                    },
                }, # end enrichment module configs
            }, # end ennrichmenst config stanza
        }, # end enrichments stanza
    ],
);
