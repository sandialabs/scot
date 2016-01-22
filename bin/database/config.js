db.config.insert({
    id: 1,
    module: "Scot::Controller::Tor",
    item:   {
        url: 'http://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=132.175.81.4',
        proxy_protos: [ 'http', 'https' ],
        proxy_url: 'http://wwwproxy.sandia.gov:80',
        ssl_opts: { verify_hostname: 0}
    }
});

db.scotmod.insert({
    id: 1,
    module: 'Scot::Util::Imap',
    attribute: "imap",
});

db.config.insert({
    id: 2,
    module: "Scot::Util::Imap",
    item: {
        mailbox: "INBOX",
        hostname: "localhost",
        port: 993,
        username: "scot-alerts",
        password: "pw_goes_here",
        ssl: [ 'SSL_verify_mode', 'SSL_VERIFY_NONE' ],
        uid: 1,
        ignore_size_errors: 1
    }
});

db.scotmod.insert({
    id: 2,
    module: "Scot::Util::Activemq",
    attribute: "amq"
});

db.config.insert({
    id: 3,
    module: "Scot::Util::Activemq",
    item: {
        host    : '127.0.0.1',
        port    : 61613,
    }
});


db.config.insert({
    id: 4,
    module: "backup",
    item:   {
        pidfile:    "/var/run/scot.backup.pid",
        location:   "/var/backup/scotdump",
        tarloc:     "/var/backup/snapshots/",
        cleanup:    1,
    }
});
