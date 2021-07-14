%environment = (
    mozilla_public_suffix_file  => '/opt/scot/etc/public_suffix_list.dat',
    location    => "snl",
    site_identifier    => "snl",
    default_share_policy    => "none",
    time_zone   => "America/Denver",
    # server name of the SCOT server
    servername  => 'as3001snllx',
    # username with sufficient scot perms to create alert(groups)
    username    => 'scot-alerts',
    # the password for that user
    # password    => 'jEm9-tun',       # password  
    # password    => 'Pruen$h6',       # password  
    # password    => 'r6im+Zuc',       # password  
    password    => 'Yber2u%u',       # password  
    # authentication type: RemoteUser, LDAP, Local
    authtype    => 'RemoteUser',
    # interactive
    interactive => 0,
    # max workers
    max_workers => 12,
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
    topic       => '/topic/scot',
    default_owner   => "scot-admin",

    # modules used by flair app
    modules => [
        {
            attr    => 'img_munger',
            class   => 'Scot::Util::ImgMunger',
            config  => {
                html_root   => "/cached_images",
                image_dir   => "/opt/scot/public/cached_images",
                storage     => "local",
            },
        },
        {
            attr    => 'scot',
            class   => 'Scot::Util::ScotClient',
            config  => {
                servername  => 'as3002snllx',
                # username with sufficient scot perms to create alert(groups)
                username    => 'scot-alerts',
                # the password for that user
                # password    => 'jEm9-tun',       # password  
                # password    => 'Pruen$h6',       # password  
                # password    => 'r6im+Zuc',       # password  
                password    => 'Yber2u%u',       # password  
                # authentication type: RemoteUser, LDAP, Local
                authtype    => 'RemoteUser',
            },
        },
        {
            attr    => 'mongo',
            class   => 'Scot::Util::MongoFactory',
            config  => {
                db_name         => 'scot-testing',
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
            attr    => 'enrichments',
            class   => 'Scot::Util::Enrichments',
            config  => {
                # mappings map the enrichments that are available 
                # for a entity type
                mappings    => {
                    ipaddr      => [ qw(splunk ick_ip geoip robtex_ip blocklist3 ) ],
                    email       => [ qw(splunk ) ],
                    md5         => [ qw(splunk hybrid_docid ) ],
                    sha1        => [ qw(splunk ) ],
                    sha256      => [ qw(splunk ) ],
                    domain      => [ qw(splunk robtex_dns blocklist3) ],
                    file        => [ qw(splunk  ) ],
                    ganalytics  => [ qw(splunk  ) ],
                    snumber     => [ qw(splunk ick_snumber  ) ],
                    message_id  => [ qw(splunk hybrid_msgid) ],
                    lb_scan_id  => [ qw(splunk likaboss) ],
                    uuid1       => [ qw(splunk likaboss) ],
                },

                # foreach enrichment listed above place any 
                # config info for it here
                enrichers => {
                    blocklist3     => {
                        type    => 'native',
                        module  => 'Scot::Util::Blocklist3',
                        config  => {
                            servername  => 'blocklist.sandia.gov',
                            username    => 'scot-alerts',
                            password    => 'Yber2u%u',       # password  
                        }
                    },
                    sidd_old    => {
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
                    likaboss     => {
                        type    => 'internal_link',
                        url     => "https://lb.sandia.gov/search/%s",
                        field   => "value",
                        title   => 'Lookup in Likaboss',
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
                }, # end enrichment module enrichers
            }, # end ennrichmenst config stanza
        }, # end enrichments stanza
        {
            attr    => 'extractor',
            class   => 'Scot::Extractor::Processor',
            config  => {
                suffixfile  => '/opt/scot/etc/effective_tld_names.dat',
            },
        },
        {
            attr    => 'regex',
            class   => 'Scot::Extractor::Regex',
            config  => {
                entity_regexes  => [
                    {
                        type    => 'snumber',
                        regex   => qr{\b([sS][0-9]{6,7})\b}xms,
                        order   => 500,
                    },
                    {
                        type    => 'sandia_server',
                        regex   => qr{\bas[0-9]+snl(lx|nt)\b}xims,
                        order   => 500,
                    },
                ],

            },
        },
    ],
);
