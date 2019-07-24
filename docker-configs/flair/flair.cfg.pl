%environment = (
    time_zone   => 'America/Denver',
    # this does flairing for DNS
    mozilla_public_suffix_file  => '/opt/scot/etc/public_suffix_list.dat',
    # server name of the SCOT server
    servername  => 'scot',
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
    ## Flair.pm needs to know how to connect to the ActiveMQ topic
    stomp_host  => "activemq",
    stomp_port  => 61613,
    topic       => "/topic/scot",
    ## updates to flair-ed entries and alerts will be done by this account
    default_owner   => "scot-admin",
    # modules used by flair app
    modules => [
        {
            attr    => 'img_munger',
            class   => 'Scot::Util::ImgMunger',
            config  => {
            },
        },
        {
            attr    => 'extractor',
            class   => 'Scot::Extractor::Processor',
            config  => {
                suffixfile  => '/opt/scot/etc/effective_tld_names.dat',
            },
        },
        {
            attr    => 'scot',
            class   => 'Scot::Util::ScotClient',
            config  => {
                servername  => 'scot',
                # username with sufficient scot perms to create alert(groups)
                username    => 'scot-alerts',
                # the password for that user
                password    => 'changemenow',
                # authentication type: RemoteUser, LDAP, Local
                authtype    => 'Local',
            },
        },
        {
            attr    => 'mongo',
            class   => 'Scot::Util::MongoFactory',
            config  => {
                db_name         => 'scot-prod',
                host            => 'mongodb://mongodb',
                write_safety    => 1,
                find_master     => 1,
            },
        },
        {
            attr    => 'mq',
            class   => 'Scot::Util::Messageq',
            config  => {
                destination => "scot",
                stomp_host  => "activemq",
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
                    ipaddr      => [ qw(splunk geoip robtex_ip ) ],
                    email       => [ qw(splunk ) ],
                    md5         => [ qw(splunk ) ],
                    sha1        => [ qw(splunk ) ],
                    sha256      => [ qw(splunk ) ],
                    domain      => [ qw(splunk robtex_dns ) ],
                    file        => [ qw(splunk  ) ],
                    ganalytics  => [ qw(splunk  ) ],
                    snumber     => [ qw(splunk ) ],
                    message_id  => [ qw(splunk ) ],
                },

                # foreach enrichment listed above place any 
                # config info for it here
                enrichers => {
                    geoip   => {
                        type    => 'native',
                        module  => 'Scot::Util::Geoip',
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
                        url     => 'https://splunk.domain.tld/en-US/app/search/search?q=search%%20%s',
                        field   => 'value',
                        title   => 'Search on Splunk',
                    },
                }, # end enrichment module enrichers
            }, # end ennrichmenst config stanza
        }, # end enrichments stanza
        {
            attr    => 'regex',
            class   => 'Scot::Extractor::Regex',
            config  => {
                entity_regexes  => [
                ],
            },
        },  
    ],
    # future use:
    location                => "scot_demo",
    site_identifier         => "scot_demo",
    default_share_policy    => "none",
);
