#!/usr/bin/env perl

use lib '../../lib';
use Scot::Util::Metrics;
use Scot::Env;
use Data::Dumper;
use v5.18;

my $env = Scot::Env->new(config_file => './scot.cfg.pl');

my $mets = Scot::Util::Metrics->new(env => $env);

my $now = $env->now;
my $day = 24 * 60 * 60;

for (my $i = $now; $i > ($now - (7 * $day)); $i -= $day ) {
    my $dt = DateTime->from_epoch(epoch => $i);
    my %r = $mets->get_avg_response_time($i, "day");
    say $dt->mdy;
    my $rts = $r{all};
    my $t   = $mets->get_human_time($rts);
    say "avg response time = $t";
}

my $dt = DateTime->new( year => 2017, month => 12 );
my $epoch = $dt->epoch();
my %r = $mets->get_avg_response_time($epoch, "month");
my $month   = $dt->month;
my $t = $mets->get_human_time($r{all});
say "avg response for month of $month was $t";

$dt = DateTime->new( year => 2017);
$epoch = $dt->epoch();
%r = $mets->get_avg_response_time($epoch, "month");
my $year   = $dt->year;
my $t = $mets->get_human_time($r{all});
say "avg response for year of $year was $t";
