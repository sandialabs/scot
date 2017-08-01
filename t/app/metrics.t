#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../../lib/';
use Scot::Env;
use Test::More;
use DateTime;
use Data::Dumper;

my $config_file = "./metrics.cfg.pl";
my $env = Scot::Env->new( config_file => $config_file );

use_ok('Scot::App::Metrics');

my $metrics = Scot::App::Metrics->new( env => $env );

print "Testing get_first_month_of_quarter\n";

is($metrics->get_first_month_of_quarter(1), 10, "1st quarter correct");
is($metrics->get_first_month_of_quarter(2), 1, "2nd quarter correct");
is($metrics->get_first_month_of_quarter(3), 4, "3rd quarter correct");
is($metrics->get_first_month_of_quarter(4), 7, "4th quarter correct");

print "Testing Beginning of previous_quarter\n";

my $testdt  = DateTime->new(
    year    => 2016,
    month   => 11,
    day     => 6,
    hour    => 14,
    minute  => 4,
    second  => 20,
);

my $beg_prev_dt = $metrics->beginning_of_previous_quarter($testdt);

is($beg_prev_dt->year, 2016, "year correct");
is($beg_prev_dt->month, 7, "month correct");
is($beg_prev_dt->day, 1, "day correct");

print "Testing Rollup period for hour\n";
my ($sdt, $edt) = $metrics->get_rollup_period("hour", $testdt);
is (ref($sdt), "DateTime", "Got a start DateTime");
is (ref($edt), "DateTime", "Got a end   DateTime");
is ($sdt->year, 2016, "start rollup year correct");
is ($sdt->month, 11, "start rollup month correct");
is ($sdt->day, 6, "start rollup day correct");
is ($sdt->hour, 13, "start rollup hour correct");
is ($sdt->minute, 0, "start rollup minute correct");
is ($sdt->second, 0, "start rollup second correct");
is ($edt->year, 2016, "start rollup year correct");
is ($edt->month, 11, "start rollup month correct");
is ($edt->day, 6, "start rollup day correct");
is ($edt->hour, 13, "start rollup hour correct");
is ($edt->minute, 59, "start rollup minute correct");
is ($edt->second, 59, "start rollup second correct");
ok ($edt->epoch > $sdt->epoch, "order is correct");

print "Testing Rollup period for day\n";
   ($sdt, $edt) = $metrics->get_rollup_period("day", $testdt);
is (ref($sdt), "DateTime", "Got a start DateTime");
is (ref($edt), "DateTime", "Got a end   DateTime");
is ($sdt->year, 2016, "start rollup year correct");
is ($sdt->month, 11, "start rollup month correct");
is ($sdt->day, 5, "start rollup day correct");
is ($sdt->hour, 0, "start rollup hour correct");
is ($sdt->minute, 0, "start rollup minute correct");
is ($sdt->second, 0, "start rollup second correct");
is ($edt->year, 2016, "start rollup year correct");
is ($edt->month, 11, "start rollup month correct");
is ($edt->day, 5, "start rollup day correct");
is ($edt->hour, 23, "start rollup hour correct");
is ($edt->minute, 59, "start rollup minute correct");
is ($edt->second, 59, "start rollup second correct");
ok ($edt->epoch > $sdt->epoch, "order is correct");

print "Testing Rollup period for month\n";
   ($sdt, $edt) = $metrics->get_rollup_period("month", $testdt);
is (ref($sdt), "DateTime", "Got a start DateTime");
is (ref($edt), "DateTime", "Got a end   DateTime");
is ($sdt->year, 2016, "start rollup year correct");
is ($sdt->month, 10, "start rollup month correct");
is ($sdt->day, 1, "start rollup day correct");
is ($sdt->hour, 0, "start rollup hour correct");
is ($sdt->minute, 0, "start rollup minute correct");
is ($sdt->second, 0, "start rollup second correct");
is ($edt->year, 2016, "start rollup year correct");
is ($edt->month, 10, "start rollup month correct");
is ($edt->day, 31, "start rollup day correct");
is ($edt->hour, 23, "start rollup hour correct");
is ($edt->minute, 59, "start rollup minute correct");
is ($edt->second, 59, "start rollup second correct");
ok ($edt->epoch > $sdt->epoch, "order is correct");

print "Testing Rollup period for year\n";
   ($sdt, $edt) = $metrics->get_rollup_period("year", $testdt);
is (ref($sdt), "DateTime", "Got a start DateTime");
is (ref($edt), "DateTime", "Got a end   DateTime");
is ($sdt->year, 2015, "start rollup year correct");
is ($sdt->month, 1, "start rollup month correct");
is ($sdt->day, 1, "start rollup day correct");
is ($sdt->hour, 0, "start rollup hour correct");
is ($sdt->minute, 0, "start rollup minute correct");
is ($sdt->second, 0, "start rollup second correct");
is ($edt->year, 2015, "start rollup year correct");
is ($edt->month, 12, "start rollup month correct");
is ($edt->day, 31, "start rollup day correct");
is ($edt->hour, 23, "start rollup hour correct");
is ($edt->minute, 59, "start rollup minute correct");
is ($edt->second, 59, "start rollup second correct");
ok ($edt->epoch > $sdt->epoch, "order is correct");

print "Testing Rollup period for quarter\n";
   ($sdt, $edt) = $metrics->get_rollup_period("quarter", $testdt);
is (ref($sdt), "DateTime", "Got a start DateTime");
is (ref($edt), "DateTime", "Got a end   DateTime");
is ($sdt->year, 2016, "start rollup year correct");
is ($sdt->month, 7, "start rollup month correct");
is ($sdt->day, 1, "start rollup day correct");
is ($sdt->hour, 0, "start rollup hour correct");
is ($sdt->minute, 0, "start rollup minute correct");
is ($sdt->second, 0, "start rollup second correct");
is ($edt->year, 2016, "start rollup year correct");
is ($edt->month, 9, "start rollup month correct");
is ($edt->day, 30, "start rollup day correct");
is ($edt->hour, 23, "start rollup hour correct");
is ($edt->minute, 59, "start rollup minute correct");
is ($edt->second, 59, "start rollup second correct");
ok ($edt->epoch > $sdt->epoch, "order is correct");

my $trickydt  = DateTime->new(
    year    => 2016,
    month   => 1,
    day     => 31,
    hour    => 0,
    minute  => 4,
    second  => 0,
);
print "Testing Rollup period \n";
   ($sdt, $edt) = $metrics->get_rollup_period("month", $trickydt);
is (ref($sdt), "DateTime", "Got a start DateTime");
is (ref($edt), "DateTime", "Got a end   DateTime");
is ($sdt->year, 2015, "start rollup year correct");
is ($sdt->month, 12, "start rollup month correct");
is ($sdt->day, 1, "start rollup day correct");
is ($sdt->hour, 0, "start rollup hour correct");
is ($sdt->minute, 0, "start rollup minute correct");
is ($sdt->second, 0, "start rollup second correct");
is ($edt->year, 2015, "start rollup year correct");
is ($edt->month, 12, "start rollup month correct");
is ($edt->day, 31, "start rollup day correct");
is ($edt->hour, 23, "start rollup hour correct");
is ($edt->minute, 59, "start rollup minute correct");
is ($edt->second, 59, "start rollup second correct");
ok ($edt->epoch > $sdt->epoch, "order is correct");

print "Testing pyramid (month) report\n";
my $pyramid = $metrics->pyramid("month");
print Dumper($pyramid)."\n";

print "Testing Alert Response\n";
my $response = $metrics->alert_response("month");
print Dumper($response);

print "Testing alert promotiong type\n";
my $results = $metrics->alert_promotion_type("month");
print Dumper($results);

done_testing();
exit 0;
