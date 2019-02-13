#!/usr/bin/env perl

use warnings;
use strict;
use v5.18;
use lib '../../lib';

use Data::Dumper;
use Test::More;
use Scot::Env;
use Scot::Factory::Logger;

my $factory = Scot::Factory::Logger->new(
    config  => {
        logger_name     => 'SCOT',
        layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
        appender_name   => 'scot_log',
        logfile         => '/var/log/scot/scot.test.log',
        log_level       => 'DEBUG',
    },
);

is (ref($factory), "Scot::Factory::Logger", "Factory built");

my $product = $factory->make;

is (ref($product), $factory->product, "Build correct product");

done_testing();
exit 0;
