// SCOT Config Bootstrap File
//
// Edit this file to your desired settings prior to completing the SCOT install
//

// db.scotmod
// this collection identifies Perl Modules that you wish 
// to pull into the Env.pm instance that is created at SCOT 
// server start time.  These modules are then available to 
// all other sections of SCOT.
// 
// id:  int,                        this is a unique integer id, 
//                                  make sure there are no duplicates
// module: "Perl::Module::Name",    module = the string you'd use in a 
//                                  "use Data::Dumper;" like perl statement
// attribue: "attrname",            attribute = the name of the attribute 
//                                  to access this module instance
//                                  e.g. $env->ldap 

db.scotmod.insert({
    id: 1,
    module: 'Scot::Util::Imap',
    attribute: "imap",
});

db.scotmod.insert({
    id: 2,
    module: "Scot::Util::Activemq",
    attribute: "amq"
});

// db.config
// this collection stores configuration information for SCOT
// 
// id: int,             unique integer id for this config id
// module: "string",    name of the config item, either an attribute name
//                      or Perl module name.  If Perlmod then it is assumed
//                      that the config item is for a scotmod above and is 
//                      passwed to its creation
// item: json_obj,      The data you wish to turn into a perl hash, 
//                      e.g. the config data
//


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

db.config.insert({
    id: 2,
    module: "Scot::Util::Imap",
    item: {
        mailbox:    "INBOX",                
        hostname:   "localhost",
        port:       993,
        username:   "scot-alerts",      // enter the username of the inbox
        password:   "pw_goes_here",     // yes, sorry
        // adjust SSL options to your needs. in case you have self signed certs
        // ssl:        [ 'SSL_verify_mode', 'SSL_VERIFY_NONE' ],
        uid:        1,
        ignore_size_errors: 1
    }
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
        pidfile:    "/var/run/scot.backup.pid",  // pid file location
        location:   "/var/backup/scotdump",     // where to mongodump
        tarloc:     "/var/backup/snapshots/",   // where to store tar'ed dumps
        cleanup:    1,                          // remove dump after tar'ing
    }
});

db.config.insert({
    id: 5,
    module: "authtype",
    item: {
        type: "Remoteuser"      // this should match the authmode you will
                                // enter during installation
    }
});
