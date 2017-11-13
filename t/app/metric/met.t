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

use_ok('Scot::App::Metric');

my $metrics = Scot::App::Metric->new( env => $env );


my $startdt  = DateTime->new(
    year    => 2013,
    month   => 9,
    day     => 24,
    hour    => 0,
    minute  => 0,
    second  => 0,
);
my $enddt   = DateTime->new(
    year    => 2017,
    month   => 4,
    day     => 1,
    hour    => 23,
    minute  => 59,
    second  => 59,
);

# $metrics->pyramid($startdt, $enddt);
# $metrics->alert_response_time($startdt, $enddt);
# $metrics->alerttype_metrics($startdt,$enddt);
$metrics->march($startdt,$enddt);
