%environment = (
    
    location   => "snl",
    time_zone   => "America/Denver",
    # scot version
    version     => '3.5.4',

    # set this to hostname of the scot server
    servername  => '127.0.0.1',

    # the mode can be prod or dev
    mode        => 'testing',

    # authentication can be "Remoteuser", "Local", or "Ldap"
    auth_type   => 'Testing', 

    authclass   => 'Controller::Auth::Testing',

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

    alertgroup_rowlimit => 10,

    # mozilla_public_suffix_file => '/opt/scot/etc/effective_tld_names.dat',
    mozilla_public_suffix_file => '/opt/scot/etc/public_suffix_list.dat',

    # mojo defaults are values for the mojolicious startup
    mojo_defaults   => {
        # change this after install and restart scot
        secrets => [qw(scot1sfun sc0t1sc00l)],

        # see mojolicious docs 
        default_expiration  => 14400,

        # hypnotoad workers, 50-100 heavy use, 20 - 50 light
        hypnotoad_workers   => 5,
    },

    log_config => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.test.log',
        log_level       => 'TRACE',
    },

    # modules to instantiate at Env.pm startup. will be done in 
    # order of the array
    modules => [
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
                        type    => "actor",
                        regex   => qr{brown fox}ims,
                        order   => 505,
                        options => { multiword => "yes" },
                    },
                    {
                        type    => "SRStestOne",
                        regex   => qr{\b(TESTING123)\b}xms,
                        order   => 506,
                    },
                    {
                        type    => "SRStestTwo",
                        regex   => qr{\b(A129\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\b}xms,
                        order   => 507,
                    },
                ],

            },
        },
        {
            attr    => 'extractor',
            class   => 'Scot::Extractor::Processor',
            config  => {

            },
        },
    ],

);
