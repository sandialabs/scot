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
        version         => '3.1',
        default_groups  => {
            read    => ['wg-scot-foo', 'wg-scot-bar' ],
            modify  => ['wg-scot-foo', ],
        },
        test_attribute  => "cool",
        factories => [
            {
                attr     => "logger_factory",
                class    => 'Scot::Factory::Logger',
                defaults => {
                    logger_name   => 'SCOT',
                    layout        => '%d %7p [%P] %15F{1}: %4L %m%n',
                    appender_name => 'scot_log',
                    logfile       => '/var/log/scot/scot.test.log',
                    log_level     => 'DEBUG',
                },
            },
            {
                attr     => "mongo_factory",
                class    => 'Scot::Factory::Mongo',
                defaults => {
                    db_name      => 'scot-testing',
                    host         => 'mongodb://localhost',
                    write_safety => 1,
                    find_master  => 1,
                },
            },
            {
                attr     => "stomp_factory",
                class    => 'Scot::Factory::Stomp',
                defaults => {
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
            {
                attr    => 'mongo',
                class   => 'Scot::Factory::Mongo',
                factory => 'mongo_factory',
                config  => {
                    log_level   => 'TRACE',
                },
            },
            {
                attr    => 'stomp_bar',
                class   => 'Scot::Factory::Stomp',
                factory => 'stomp_factory',
                config  => {
                    destination => "/queue/bar",
                },
            }
        ]
    },
});

is (ref($env), "Scot::Env", "Scot::Env instantiated");
is ($env->test_attribute, "cool", "test attribute present and correct");
is (ref($env->logger_factory), "Scot::Factory::Logger", "Logger Factory OK");
is (ref($env->log), "Log::Log4perl::Logger", "Logger was instantiated");
is (ref($env->img_munger), "Scot::Util::ImgMunger", "ImgMunger Module instantiated");
is (ref($env->mongo), "Meerkat", "Mongo factory made Meerkat object");
is (ref($env->stomp_bar), "AnyEvent::STOMP::Client", "Stomp factory made AE::Stomp::Client");

# this tests if the stomp hosts are different
#my $stomp_bar   = $env->stomp_bar;
#my $stomp_boo   = $env->stomp_factory->make({ 
#    host        => 'notlocalhost',
#    destination => "/topic/boo" });
#print Dumper($stomp_bar),Dumper($stomp_boo),"\n";

# TODO: read from foobar.test.log and make sure message is there
#system("cat /dev/null > /var/log/scot/foobar.test.log");
#my $nextlogger = $env->logger_factory->make({
#    logger_name   => 'SCOT',
#    layout        => '%d %7p [%P] %15F{1}: %4L %m%n',
#    appender_name => 'foo_log',
#    logfile       => '/var/log/scot/foobar.test.log',
#    log_level     => 'TRACE',
#});
#$nextlogger->trace("Testing is fun");

# now test old style config file

print "------------------------------------\n";

my $env2    = Scot::Env->new({config_file => '/opt/scot/etc/scot.cfg.pl'});
is (ref($env2), "Scot::Env", "Scot::Env instantiated");
is (ref($env2->log), "Log::Log4perl::Logger", "Logger worked with old config");
is (ref($env2->mongo), "Meerkat", "So did Meerkat/Mongo");
is (ref($env2->mongoquerymaker), "Scot::Util::MongoQueryMaker", "Can access module");
is ($env2->row_limit, 100, "Can access an attribute");
is ($env2->servername, "127.0.0.1", "Can access an attribute");


done_testing();



