#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../../../lib';
use lib '/opt/scot/lib';
use Scot::Env;
use Scot::App::Metric;
use Test::More;
use DateTime;
use Data::Dumper;

my $config  = "/opt/scot/etc/metrics.cfg.pl";
my $env     = Scot::Env->new( config_file => $config );

my $m   = Scot::App::Metric->new( env => $env );

my $todaydt = DateTime->today;
my $stopdt  = $todaydt->clone();
$todaydt->set(hour=>23, minute=>59, second=>59);
$stopdt->subtract(days => 70);
$stopdt->set(hour=>0, minute=>0, second=>0);

#$m->march([qw(alert_response_time alerttype_metrics promoted_count alert_open_closed)],
$m->march([qw(alert_response_time alerttype_metrics)],
          $todaydt, $stopdt);


