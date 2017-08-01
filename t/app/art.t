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


my $enddt  = DateTime->new(
    year    => 2010,
    month   => 1,
    day     => 1,
    hour    => 0,
    minute  => 0,
    second  => 0,
);
my $startdt   = DateTime->new(
    year    => 2017,
    month   => 5,
    day     => 1,
    hour    => 23,
    minute  => 59,
    second  => 59,
);

# march marches backwards
# $metrics->march([qw(alert_response_time)],$startdt,$enddt);
# $metrics->march([qw(promoted_count)],$startdt,$enddt);
# $metrics->march([qw(alert_open_closed)],$startdt,$enddt);
$metrics->march([qw(alerttype_metrics)],$startdt, $enddt);

