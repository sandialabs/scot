%environment = (
    
    time_zone   => 'America/Denver',
    # scot version
    version     => '3.5.1',

    # set this to hostname of the scot server
    servername  => '127.0.0.1',

    # the mode can be prod or dev
    mode        => 'prod',

    # authentication can be "Remoteuser", "Local", or "Ldap"
    auth_type   => 'Local', 

    # group mode can be "local" or "ldap"
    group_mode  => 'local',

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

    stomp_host  => "localhost",
    stomp_port  => 61613,
    topic       => "/topic/scot",

    # location and site_identifier (future use)
    location                => 'demosite',
    site_identifier         => "demosite",
    default_share_policy    => "none",

    # mojo defaults are values for the mojolicious startup
    mojo_defaults   => {
        # change this after install and restart scot
        secrets => [qw(scot1sfun sc0t1sc00l)],

        # see mojolicious docs 
        default_expiration  => 14400,

        # hypnotoad workers, 50-100 heavy use, 20 - 50 light
        # hypnotoad_workers   => 75,
        hypnotoad => {
            listen  => [ 'http://localhost:3000?reuse=1' ],
            workers => 20,
            clients => 1,
            proxy   => 1,
            pidfile => '/var/run/hypno.pid',
            heartbeat_timeout   => 40,
        },

    },

    log_config => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.log',
        log_level       => 'DEBUG',
    },

    cgi_ids_config  => {
        whitelist_file  => '',
        disable_filters => [],
    },

    # this file helps scot determine valid domain "entities"
    # keep up to date, by creating a root cron job that does the following:
    # @daily (cd /opt/scot/etc; export https_proxy=yourproxy.com; wget -q -N https://publicsuffix.org/list/public_suffix_list.dat)
    mozilla_public_suffix_file  => '/opt/scot/etc/public_suffix_list.dat',

    # modules to instantiate at Env.pm startup. will be done in 
    # order of the array
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
            attr    => "es",
            class   => "Scot::Util::ElasticSearch",
            config  => {
                nodes   => [qw(localhost:9200)],
            },
        },
        {
            attr    => 'esproxy',
            class   => 'Scot::Util::ESProxy',
            config  => {
                nodes       => [ qw(localhost:9200) ],
                max_workers => 1,
                proto       => 'http',
                servername  => 'localhost',
                serverport  => 9200,
                username    => ' ',
                password    => ' ',
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
                hostname    => 'mail.domain.tld',# hostname of the imap server
                port        => 993,              # port of the imap server
                username    => 'scot-alerts',    # username  of the 
                                                 # account receiving alert email
                password    => 'changemenow',    # password  
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
                    ipaddr      => [ qw(splunk geoip robtex_ip ) ],
                    ipv6        => [ qw(splunk geoip robtex_ip ) ],
                    email       => [ qw(splunk ) ],
                    md5         => [ qw(splunk ) ],
                    sha1        => [ qw(splunk ) ],
                    sha256      => [ qw(splunk ) ],
                    domain      => [ qw(splunk robtex_dns ) ],
                    file        => [ qw(splunk  ) ],
                    ganalytics  => [ qw(splunk  ) ],
                    snumber     => [ qw(splunk ) ],
                    message_id  => [ qw(splunk ) ],
                    cve         => [ qw(cve_lookup ) ],
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
                    cve_lookup  => {
                        type    => 'external_link',
                        url     => "https://cve.mitre.org/cgi-bin/cvename.cgi?name=%s",
                        field   => "value",
                        title   => "Lookup CVE description",
                    },
                }, # end enrichment module enrichers
            }, # end ennrichmenst config stanza
        }, # end enrichments stanza
        {
            attr    => 'ldap',
            class   => 'Scot::Util::Ldap',
            config  => {
                servername  => 'ldap.domain.tld',
                dn          => 'cn=cn_name,ou=local config,dc=tld',
                password    => 'changemenow',
                scheme      => 'ldap',
                group_search    => {
                    base    => 'ou=groups,ou=orgname1,dc=dcname1,dc=dcname2,dc=dcname3',
                    filter  => '(| (cn=wg-scot*))',
                    attrs   => [ 'cn' ],
                },
                user_groups => {
                    base    => 'ou=accounts,ou=ouname,dc=dcname1,dc=dcname1,dc=dcname1',
                    filter  => 'uid=%s',
                    attrs   => ['memberOf'],
                }
            }, # end ldap config
        }, # end ldap
    ],
    entity_regexes  => [],
    #
    # form contain directions on how to build the custom incident form fields
    # and signatures (and others later?)
    # 
    forms   => {
        signature  => [
            {
                type    => "textarea",
                key     => "description",
                value   => '',
                value_type => {
                    type    => 'static',
                    url     => undef,
                    key     => 'description',
                },
                label   => "Description",
                help    => "Enter a short description of the signature's purpose",
            },
            {
                type    => "input",
                key     => "type",
                value   => '',
                label   => "Type",
                help    => "Enter the signature type, e.g. yara, snort, etc.",
                value_type => {
                    type    => 'static',
                    url     => undef,
                    key     => 'type',
                },
            },
            {
                type    => "dropdown",
                key     => "prod_sigbody_id",
                value   => [],
                value_type  => {
                    type    => "dynamic",
                    url     => '/scot/api/v2/signature/%s',
                    key     => 'prod_sigbody_id',
                },
                label   => "Production Signature Body Version",
                help    => "Select the version of the signature body you wish to be used in production",
            },
            {
                type    => "dropdown",
                key     => "qual_sigbody_id",
                value   => [],
                value_type  => {
                    type    => "dynamic",
                    url     => '/scot/api/v2/signature/%s',
                    key     => 'qual_sigbody_id',
                },
                label   => "Quality Signature Body Version",
                help    => "Select the version of the signature body you wish to be used in quality",
            },
            {
                type    => "input_multi",
                key     => 'signature_group',
                value   => [],
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'signature_group',
                },
                label   => "Signature Group",
                help    => "Group signatures under common names",
            },
            {
                type    => 'input',
                key     => 'target.type',
                value   => '',
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'target.type',
                },
                label   => "Reference Type",
                help    => "The SCOT datatype that originated this signature",
            },
            {
                type    => 'input',
                key     => 'target.id',
                value   => '',
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'target.id',
                },
                help    => 'The id of the SCOT datatype that originated this sig',
                label   => "Reference ID",
            },
			{
                type    => "multi_select",
                key     => "action",
                value   => [
                    { value => 'alert',  selected => 0 },
                    { value => 'block', selected => 0 },
                ],
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'action',
                },
                label   => "Action",
                help    => "The automated action that should take place when this signature is triggered. Select multiple actions using ctrl/command key.",
            },
        ],
        incident    => [
            # substitue your text and values here to match your
            # incident types
            {
                type    => "dropdown",
                key     => 'type',
                value   => [
                    { value => 'NONE',  selected => 1 },
                    { value => 'FYI', selected => 0 },
                    { value => 'Type 1 : Root Comprimise', selected => 0 },
                    { value => 'Type 1 : User Compromise', selected => 0 },
                    { value => 'Type 1 : Loss/Theft/Missing Desktop', selected => 0 },
                    { value => 'Type 1 : Loss/Theft/Missing Laptop', selected => 0 },
                    { value => 'Type 1 : Loss/Theft/Missing Media', selected => 0 },
                    { value => 'Type 1 : Loss/Theft/Missing Other', selected => 0 },
                    { value => 'Type 1 : Malicious Code Trojan', selected => 0 },
                    { value => 'Type 1 : Malicious Code Virus', selected => 0 },
                    { value => 'Type 1 : Malicious Code Worm', selected => 0 },
                    { value => 'Type 1 : Malicious Code Other', selected => 0 },
                    { value => 'Type 1 : Web Site Defacement', selected => 0 },
                    { value => 'Type 1 : Denial of Service', selected => 0 },
                    { value => 'Type 1 : Critical Infrastructure Protection', selected => 0 },
                    { value => 'Type 1 : Unauthorized Use', selected => 0 },
                    { value => 'Type 1 : Information Compromise', selected => 0 },
                    { value => 'Type 2 : Attempted Intrusion', selected => 0 },
                    { value => 'Type 2 : Reconnaissance Activity', selected => 0 },
                ],
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'type',
                },
                label   => 'Incident Type',
                help    => "Select best match for incident type",
            }, 
            # substitute your text and values to match your incident cats
            {
                type    => "dropdown",
                key     => "category",
                value   => [
                    { value => 'NONE', selected => 1},
                    { value => 'IMI-1', selected => 0},
                    { value => 'IMI-2', selected => 0},
                    { value => 'IMI-3', selected => 0},
                    { value => 'IMI-4', selected => 0},
                ],
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'category',
                },
                label   => 'Incident Category',
                help    => "Select best match for incident category",
            },
            {
                type    => "dropdown",
                key     => "sensitivity",
                value   => [
                    {value => 'NONE', selected => 1},
                    {value => 'OUO', selected => 0},
                    {value => 'PII', selected => 0},
                    {value => 'SUI', selected => 0},
                    {value => 'UCNI', selected => 0},
                    {value => 'Other', selected => 0},
                ],
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'sensitivity',
                },
                label   => 'Incident Sensitivity',
                help    => "Select best match for incident sensitivity",
            },
            {
                type    => "dropdown",
                key     => "security_category",
                value   => [
                    {value => 'NONE', selected => 1},
                    {value => 'Low', selected => 0},
                    {value => 'Moderate', selected => 0},
                    {value => 'High', selected => 0},
                ],
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'security_category',
                },
                label   => 'Incident Security Category',
                help    => "Select best match for incident security category",
            },
            #date field for tracking when incident occurred
            {
                type    => "calendar",
                key     => "occurred",
                value   => "",
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'occurred',
                },
                label   => "Date/Time Occurred",
                help    => "Select Date/Time Incident Occurred",
            },
            {
                type    => "calendar",
                key     => "discovered",
                value   => "",
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'discovered',
                },
                label   => "Date/Time Discovered",
                help    => "Select Date/Time Incident was discovered",
            },
            {
                type    => "calendar",
                key     => "reported",
                value   => "",
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'reported',
                },
                label   => "Date/Time Reported",
                help    => "Select Date/Time Incident was reported",
            },
            {
                type    => "calendar",
                key     => "closed",
                value   => "",
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'closed',
                },
                label   => "Date/Time Closed",
                help    => "Select Date/Time Incident was closed",
            },
        ],
        incident_v2 => [
            {
                type    => 'dropdown',
                key     => 'type',
                value   => [
                    # place your types here...
                    { value => "none",      selected => 1 },
                    { value => "intrusion", selected => 0 },
                    { value => "malware",   selected => 0 },
                ],
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'type',
                },
                label   => "Incident Type",
                help    => <<'EOF',
<table>
  <tr> <th>intrusion</th><td>An intrusion occurred</td> </tr>
  <tr> <th>malware</th>  <td>Malware detected</td>      </tr>
</table>
EOF
            },
            {
                type    => "calendar",
                key     => "discovered",
                value   => "",
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'discovered',
                },
                label   => "Date/Time Discovered",
                help    => "Select Date/Time Incident was discovered",
            },
            {
                type    => "dropdown",
                key     => "severity",
                value   => [
                    {value => 'NONE', selected => 1},
                    {value => 'Low', selected => 0},
                    {value => 'Moderate', selected => 0},
                    {value => 'High', selected => 0},
                ],
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'severity',
                },
                label   => 'Incident severity',
                help    => "Select best match for incident severity",
            }, 
        ],
        guide   => [
            {
                type    => "input_multi",
                key     => "applies_to",
                value   => '',
                value_type  => {
                    type    => "static",
                    url     => undef,
                    key     => 'applies_to',
                },
                label   => 'Guide applies to',
                help    => 'Enter string matching subject that this guide applies to',
            },
        ],
    }, 
    dailybrief  => {
        mail    => {
            from    => 'scot@yourdomain.com',
            to      => 'tbruner@scotdemo.com',
            host    => 'smtp.yourdomain.com',
        },
        url     => 'https://scot.yourdomain.com/'
    },
    incident_summary_template   => <<EOF,
<table>
    <tr><th>Description</th><td><i>place description of the incident here</i></td></tr>
    <tr><th>Related Indicators</th><td><i>Place IOC's here</i></td></tr>
    <tr><th>Source Details</th><td><i>Place wource port, ip, protocol, etc. here</i></td></tr>
    <tr><th>Compromised System Details</th><td><i>Place details about compromised System here</i></td></tr>
    <tr><th>Recovery/Mitigation Actions</th><td><i>Place recovery/mitigation details here</i></td></tr>
    <tr><th>Physical Location of System</th><td><i>Place the city and State of system location</i></td></tr>
    <tr><th>Detection Details</th><td><i>Place Source, methods, or tools used to identify incident</i></td></tr>
</table>
EOF
);
