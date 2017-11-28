%environment = (
    log_config  => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.mail.log',
        log_level       => 'DEBUG',
    },
    modules => [
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
                hostname    => 'mail.scotdemo.org',# hostname of the imap server
                port        => 993,              # port of the imap server
                username    => 'scot-alerts',    # username  of the 
                                                 # account receiving alert email
                password    => 'changemenow',       # password  
                ssl         => [ 
                    'SSL_verify_mode', 0         # ssl options 
                ],                               # see perldoc IO::SSL
                uid         => 1,                # uid   IMAP config item 
                ignore_size_errors  => 1,        # ignore_size_errors 
            },
        },
        {
            attr    => 'es',
            class   => 'Scot::Util::ElasticSearch',
            config  => {
                nodes       => [ qw(localhost:9200) ],
                max_workers => 1,
            },
        },
        {
            attr    => 'scot',
            class   => 'Scot::Util::ScotClient',
            config  => {
                servername  => 'scotdemo',
                # username with sufficient scot perms to create alert(groups)
                username    => 'scot-alerts',
                # the password for that user
                password    => 'changemenow',       # password  
                # authentication type: RemoteUser, LDAP, Local
                authtype    => 'RemoteUser',
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
    ],
    get_method      => "mongo",     # other value is "rest"
    leave_unseen    => 0,
    # interactive => [ yes | no ]
    # pauses processing after each message and writes to console 
    interactive     => 'no',   
    verbose         => 1,
    # max_processes => 0 to positive int
    # number of child processes to fork to parse messages in parallel
    # 0 = disable forking and do all messages sequentially
    max_processes   => 0,       
    # fetch_mode    => [ unseen | time ]
    # unseen looks for unseen messages via imap protocol
    # time gets all message since a given time
    # both modes check unique message_id and will not reprocess something
    # already in SCOT database
    fetch_mode      => 'unseen', 
    # since     => { unit => amount }
    # hashref where key is the unit [ day, hour, minute ]
    # amount is integer value
    # used by time fetch_mode 
    since           => { hour => 2 },
    # approved_alert_domains => [ 'domain1\.org', ... ]
    # only domains listed in this array can send email to scot
    # periods need to be escaped by \
    approved_alert_domains  => [ 'watermelon.gov', 'scotdemo.org' ],
    # approve_accounts => [ 'user@email.addr' ];
    # account in this domain can also send to scot
    approved_accounts   => [ 'todd.bruner@gmail.com', 'foo@bar.com' ],
    # directory to look in for parsers
    parser_dir  => "/opt/scot/lib/Scot/Parser",
    default_groups => {
        read    => [ 'wg-scot-ir', 'wg-scot-researchers' ],
        modify  => [ 'wg-scot-ir' ],
    },
    default_owner   => 'scot-admin',
);
