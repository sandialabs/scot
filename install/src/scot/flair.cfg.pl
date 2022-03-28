%environment = (
    max_workers => 4,
    location    => 'snl',
    fetch_mode  => 'mongo',
    mozilla_public_suffix_file => '/opt/scot/etc/public_suffix_list.dat',
    log_config => {
        logger_name => 'flair',
        layout      => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name => 'regex_log',
        logfile     => '/var/log/scot/flair.log',
        log_level   => 'DEBUG',
    },
    default_groups  => {
        read    => [ 'wg-scot-ir'],
        modify  => [ 'wg-scot-ir'],
    },
    default_owner   => 'scot-admin',
    img_dir     => '/opt/scot/public/cached_images',
    html_root   => '/cahced_images',
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
            attr    => 'mq',
            class   => 'Scot::Util::Messageq',
            config  => {
                destination => 'scot',
                stomp_host  => 'localhost',
                stomp_port  => 61613,
            },
        },
    ],
    local_regexes => [
        {
            type    => 'snumber',
            regex   => '\b([sS][0-9]{6,7})\b',
            order   => 501,
            options => { multiword => "no" },
        },
        {
            type    => 'sandia_server',
            regex   => '\bas[0-9]+snl(lx|nt)\b',
            order   => 500,
            options => { multiword => "no" },
        },
    ],
    lwp         => {
        use_proxy           => 1,
        timeout             => 10,
        ssl_verify_mode     => 1,
        verify_hostaname    => 1,
        ssl_ca_path         => '/etc/ssl/certs',
        proxy_protocols     => ['http', 'https'],
        proxy_uri           => 'http://proxy.sandia.gov:80',
        lwp_ua_string       => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit  /537.36 (KHTML, like Gecko) Chrome/41.0.2227.1 Safari/537.36",
    },
);
