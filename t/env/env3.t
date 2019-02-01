#!/usr/bin/env perl

use strict;
use warnings;
use lib '../../lib';

use Test::More;
use Test::Deep;
use Scot::Env;
use Data::Dumper;

my $env = Scot::Env->new({
    config_href => {
        version         => '3.9999999.1',
        default_groups  => {
            read    => ['wg-scot-foo', 'wg-scot-bar' ],
            modify  => ['wg-scot-foo', ],
        },
        factories   => [
            {
                attr    => "logger_factory",
                class   => 'Scot::Factory::Logger',
                config  => {
                    logger_name     => 'SCOT',
                    layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
                    appender_name   => 'scot_log',
                    logfile         => '/var/log/scot/scot.test.log',
                    log_level       => 'DEBUG',
                },
            },
            {
                attr    => "mongo_factory",
                class   => 'Scot::Factory::Mongo',
                config  => {
                    db_name         => 'scot-testing',
                    host            => 'mongodb://localhost',
                    write_safety    => 1,
                    find_master     => 1,
                },
            },
            {
                attr    => "stomp_factory",
                class   => 'Scot::Factory::Stomp',
                config  => {
                    host        => 'localhost',
                    post        => 61613,
                    destination => '/queue/foo',
                },
            },
        ],
        modules => [
            {
                attr    => 'img_munger',
                class   => 'Scot::Util::ImgMunger',
                config  => {
                    html_root   => "/cached_images",
                    image_dir   => "/opt/scot/public/caced_images",
                    storage     => "local",
                },
            },
            {
                attr    => 'mongoquerymaker',
                class   => 'Scot::Util::MongoQueryMaker',
                config  => {
                },
            },
        ]
    },
});

is (ref($env), "Scot::Env", "Scot::Env instantiated");
done_testing();



