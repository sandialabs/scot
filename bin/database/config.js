db.config.insert({
    module: "Scot::Controller::Tor",
    item:   {
        url: 'http://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=132.175.81.4',
        proxy_protos: [ 'http', 'https' ],
        proxy_url: 'http://wwwproxy.sandia.gov:80',
        ssl_opts: { verify_hostname: 0}
    }
});

db.scotmod.insert({
    module: 'Scot::Util::Imap',
    attribute: "imap",
});
db.config.insert({
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
    module: "Scot::Util::Activemq",
    attribute: "amq"
});
db.config.insert({
    module: "Scot::Util::Activemq",
    item: {
        host    => '127.0.0.1',
        port    => 61613,
    }
});


