%environment = (

    # row_limit limits the number of alerts in an alertgroup
    row_limit   => 100,
    
    # number of secs that mojo session is valid
    session_expiration  => 3600 * 4,

    time_zone   => "America/Denver",
    # scot version
    version     => '3.5.1',

    # set this to hostname of the scot server
    servername  => '127.0.0.1',

    # the mode can be prod or dev
    mode        => 'prod',

    # authentication can be "Remoteuser", "Local", or "Ldap"
    auth_type   => 'Remoteuser', 

    authclass   => 'Controller::Auth::Remoteuser',

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

    mail_watch_senders  => [
        qw(
            SPLUNK-DEV
            SPLUNK
            SPLUNKJOBS
        )
    ],

    # mojo defaults are values for the mojolicious startup
    mojo_defaults   => {
        # change this after install and restart scot
        secrets => [qw(scot1sfun sc0t1sc00l)],

        # see mojolicious docs 
        default_expiration  => 14400,

        # hypnotoad workers, 50-100 heavy use, 20 - 50 light
        # hypnotoad_workers   => 75,
        hypnotoad   => {
            listen  => [ 'http://localhost:3000?reuse=1' ],
            workers => 75,
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

    cgi_ids_config => {
    #    filters_file    => '/opt/scot/etc/cgi_ids_filter.xml',
    #    whitelist_file  => '',
    #    disable_filters => [],
    },

    apikeys => {
        sarlacc => "apikey=eyJhbGciOiJIUzI1NiJ9.eyJ1aWQiOiJzY290In0.SGbgQeNlOu_971nU706rFuJXqW4GWoCjhoBd2wMgPqo",
    },

    entry_actions   => {
        fileinfo    => sub {
            my $href    = shift;
            my $server  = shift;
            $server .= ".sandia.gov";
            my $url     = "https://sarlacc.gibson.sandia.gov/api/scot/scan?";
            my $body    = $href->{body};
            $body   =~ m{file/([0-9]+)\?download=1};
            $fid    = $1; # first match
            my @params  = (
                "apikey=eyJhbGciOiJIUzI1NiJ9.eyJ1aWQiOiJzY290In0.SGbgQeNlOu_971nU706rFuJXqW4GWoCjhoBd2wMgPqo",
                "target_id=".$href->{target}->{id},
                "target_type=".$href->{target}->{type},
                "parent_id=".$href->{id},
                "file_url="."https://$server/scot/api/v2/file/".$fid."?download=1",
            );
            $url .= join('&',@params);
            return {
                send_to_name    => "Sarlacc",
                send_to_url     => $url,
            };
        },
    },

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
            attr    => 'es',
            class   => 'Scot::Util::ElasticSearch',
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
    ],

    entity_regexes  => [
        {
            type    => 'snumber',
            regex   => qr{\b([sS][0-9]{6,7})\b}xms,
            order   => 500,
        }
    ],
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
                    key     => 'input',
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
        ],
        incident    => [
            # substitue your text and values here to match your
            # incident types
            {
                type    => "dropdown",
                key     => 'type',
                value   => [
                    { text  => 'Type1', value => 'none',  selected => 0 },
                    { text  => 'Type2', value => 'type2', selected => 0 },
                    { text  => 'Type3', value => 'type3', selected => 0 },
                ],
                label   => 'Incident Type',
                help    => "Select best match for incident type",
            },
            # substitute your text and values to match your incident cats
            {
                type    => "dropdown",
                key     => "category",
                value   => [
                    {text   => "Cat1", value => 'cat1', selected => 1},
                    {text   => "Cat2", value => 'cat2', selected => 0},
                ],
                label   => 'Incident Category',
                help    => "Select best match for incident category",
            },
            # date field for tracking when incident occurred 
            {
                type    => "calendar",
                key     => "occurred",
                value   => "",
                label   => "Date/Time Occurred",
                help    => "Select Date/Time Incident Occurred",
            },
        ],
        guide   => [
            {
                type    => "input",
                key     => "applies_to",
                value   => '',
                label   => 'Guide applies to',
                help    => 'Enter string matching subject that this guide applies to',
            },
        ],
    },
);
