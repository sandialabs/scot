%environment = (
    location    => 'snl',
    fetch_mode  => 'mongo',
    max_workers => 1,
    html_root   => '/cached_images',
    img_dir     => '/tmp/cached_images',
    lwp         => {
        use_proxy           => 1,
        timeout             => 10,
        ssl_verify_mode     => 1,
        verify_hostaname    => 1,
        ssl_ca_path         => '/etc/ssl/certs',
        proxy_protocols     => ['http', 'https'],
        proxy_uri           => 'http://wwwproxy.sandia.gov:80',
        lwp_ua_string       => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit  /537.36 (KHTML, like Gecko) Chrome/41.0.2227.1 Safari/537.36",
    },
    log_config => {
        logger_name => 'imgmunger_test',
        layout      => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name => 'imgmunger_log',
        logfile     => '/var/log/scot/test.log',
        log_level   => 'DEBUG',
    },
    modules => [
        {
            attr    => 'mongo',
            class   => 'Scot::Util::MongoFactory',
            config  => {
                db_name         => 'scot-test',
                host            => 'mongodb://localhost',
                write_safety    => 1,
                find_master     => 1,
            },
        },
    ],
);
