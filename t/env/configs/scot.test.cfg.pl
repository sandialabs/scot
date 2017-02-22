%environment = (
    
    # scot version
    version     => '3.5.1',

    # set this to hostname of the scot server
    servername  => '127.0.0.1',

    # the mode can be prod or dev
    mode        => 'prod',

    # authentication can be "Remoteuser", "Local", or "Ldap"
    auth_type   => 'Remoteuser', 

    # group mode can be "local" or "ldap"
    group_mode  => 'ldap',

    # default owner of new stuff
    default_owner   => 'scot-admin',

    # default set of groups to apply to stuff
    default_groups  => {
        read    => [ 'wg-scot-ir', 'wg-scot-researchers' ],
        modify  => [ 'wg-scot-ir' ],
    },

    # the group that can perform admin functions
    admin_group => 'wg-scot-admin',

    # filestore is where scot stores uploaded and extracted files
    file_store_root => '/opt/scotfiles',

    epoch_cols  => [ qw(when updated created occurred) ],

    int_cols    => [ qw(views) ],

    site_identifier => 'Sandia',

    default_share_policy => 1,

    share_after_time    => 10, # minutes

    # mojo defaults are values for the mojolicious startup
    mojo_defaults   => {
        # change this after install and restart scot
        secrets => [qw(scot1sfun sc0t1sc00l)],

        # see mojolicious docs 
        default_expiration  => 14400,

        # hypnotoad workers, 50-100 heavy use, 20 - 50 light
        hypnotoad_workers   => 75,
    },

    log_config => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.log',
        log_level       => 'DEBUG',
    },

    # modules to instantiate at Env.pm startup. will be done in 
    # order of the array
    modules => [
        {
            attr    => 'scot',
            class   => 'Scot::Util::Scot2',
            config  => {
                servername  => 'localhost',
                username    => 'scot-alerts',
                password    => 'changemenow',
                authtype    => 'Local',
            },
        },
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
            attr    => 'mongoquerymaker',
            class   => 'Scot::Util::MongoQueryMaker',
            config  => {
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
            attr    => 'imap',
            class   => 'Scot::Util::Imap',
            config  => {
                mailbox     => 'INBOX',          # mailbox, typically INBOX
                hostname    => 'mail.sandia.gov',# hostname of the imap server
                port        => 993,              # port of the imap server
                username    => 'scot-alerts',    # username  of the 
                                                 # account receiving alert email
                password    => 'ukeSb=r9',       # password  
                ssl         => [ 
                    'SSL_verify_mode', 0         # ssl options 
                ],                               # see perldoc IO::SSL
                uid         => 1,                # uid   IMAP config item 
                ignore_size_errors  => 1,        # ignore_size_errors 
            },
        },
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
        {
            attr    => 'ldap',
            class   => 'Scot::Util::Ldap',
            config  => {
                servername  => 'sec-ldap-nm.sandia.gov',
                dn          => 'cn=snlldapproxy,ou=local config,dc=gov',
                password    => 'snlldapproxy',
                scheme      => 'ldap',
                group_search    => {
                    base    => 'ou=groups,ou=snl,dc=nnsa,dc=doe,dc=gov',
                    filter  => '(| (cn=wg-scot*))',
                    attrs   => [ 'cn' ],
                },
                user_groups => {
                    base    => 'ou=accounts,ou=snl,dc=nnsa,dc=doe,dc=gov',
                    filter  => 'uid=%s',
                    attrs   => ['memberOf'],
                }
            }, # end ldap config
        }, # end ldap
        {
            attr    => 'extractor',
            class   => 'Scot::Util::EntityExtractor',
            config  => {
                suffixfile  => '/opt/scot/etc/effective_tld_names.dat',
            },
        },
        {
            attr    => 'img_munger',
            class   => 'Scot::Util::ImgMunger',
            config  => {
                html_root   => "/cached_images",
                image_dir   => "/opt/scot/public/cached_images",
                storage     => "local",
            },
        },
    ],
);
