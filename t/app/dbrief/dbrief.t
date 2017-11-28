#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../../lib/';
use Scot::Env;
use Test::More;
use DateTime;
use Data::Dumper;
system("mongo scot-testing < ../../install/src/mongodb/reset.js 2>&1 > /dev/null");
my $config_file = "./dbrief.cfg.pl";
my $env = Scot::Env->new( config_file => $config_file );

use_ok('Scot::App::Dbrief');

my $brief = Scot::App::Dbrief->new( env => $env );
my $dt      = DateTime->now;
my $ymd     = $dt->ymd;
say $ymd;
my $header  = $brief->build_header();
my $expect  = <<"EOF";
<html>
  <head>
    <style>
    <title>SCOT Daily Brief</title>
  </head>
  <body>
    <h1>SCOT Daily Brief</h1>
    <h2>$ymd</h2>
EOF

is ( $header, $expect, "header is correct");

# generate data
my $statcol = $env->mongo->collection('Stat');
$statcol->put_stat("alerts created", 4);


my @results = $brief->build_alert_report;

is ( $results[0], 1, "correct dow");
is ( $results[1], 4, "correct count");
is ( $results[2]->{value}->{sum}, 4, "correct item in data" );


done_testing();
exit 0;

