%environment = (
    log_config  => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.mail.log',
        log_level       => 'DEBUG',
    },
    modules => [
    ],
    get_method      => "mongo",     # other value is "rest"
    leave_unseen    => 1,
    # interactive => [ yes | no ]
    # pauses processing after each message and writes to console 
    interatcive     => 'no',   
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
    approved_alert_domains  => [ 'sandia.gov' ],
    # approve_accounts => [ 'user@email.addr' ];
    # account in this domain can also send to scot
    approved_accounts   => [ 'g1169@att.att-mail.com' ],
);
