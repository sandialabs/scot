####
#### alert.cfg.pl
####
#### Used to configure the SCOT email alert input program
#### bin/alert.pl which uses Scot::App::Mail
####

%environment = (

    ## See perl DateTime documenation for values matching your locale
    time_zone   => 'America/Denver',

    ## Set up Scot Logging to your liking.  See Log::Log4perl documentaton
    ## for details on layout and log_level.  By default, log_level of DEBUB
    ## is very verbose, but is probably the level you want to be able to 
    ## figure out an error after it occurs.
    log_config  => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.mail.log',
        log_level       => 'DEBUG',
    },

    ## MODULES
    ## Each hash in the following array, will result in an attribute
    ## being created in the Scot/Env.pm module that points to the class
    ## described.  if you ever get a "cant find foo in Scot::Env" you might
    ## be missing something here

    modules => [
        ## describe to SCOT how to talk to your imap server
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
        ## describe how for the Scot Perl client to find the SCOT server
        {
            attr    => 'scot',
            class   => 'Scot::Util::ScotClient',
            config  => {
                servername  => 'scotserver',
                # username with sufficient scot perms to create alert(groups)
                username    => 'scot-alerts',
                # the password for that user
                password    => 'changemenow',
                # authentication type: RemoteUser, LDAP, Local
                authtype    => 'Local',
            },
        },
        ## mongodb connection information
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
        ## ActiveMQ connection info
        {
            attr    => 'mq',
            class   => 'Scot::Util::Messageq',
            config  => {
                destination => "scot",
                stomp_host  => "localhost",
                stomp_port  => 61613,
            },
        },
        ## Elasticsearch connection info
        {
            attr    => 'es',
            class   => 'Scot::Util::ElasticSearch',
            config  => {
                nodes       => [ qw(localhost:9200) ],
                max_workers => 1,
            },
        },
    ],
    ## parser_dir is where to find the modules that can parse the emails
    parser_dir  => '/opt/scot/lib/Scot/Parser',
    ## alert.pl can utilize rest or direct mongo connection to input data
    get_method      => "mongo",     # other value is "rest"
    ## leave_unseen = 1 means SCOT will leave emails marked "unread" 
    ## leave_unseen = 0 means SCOT marks emails read after processing
    leave_unseen    => 1,
    # interactive => [ yes | no ]
    # pauses processing after each message and writes to console 
    interactive     => 'no',   
    verbose         => 1,
    # max_processes => 0 to positive int
    # number of child processes to fork to parse messages in parallel
    # 0 = disable forking and do all messages sequentially
    # recommendation is 5-10 in production, 0 for testing.
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
    approved_alert_domains  => [ 'domain\.tld' ],
    # approve_accounts => [ 'user@email.addr' ];
    # account in this domain can also send to scot
    approved_accounts   => [ 'user@server.domain.tld' ],
);
