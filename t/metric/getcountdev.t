#!/usr/bin/env perl

use lib '../../lib';
use Scot::Util::Metrics;
use Scot::Env;
use Data::Dumper;
use DateTime;
use v5.18;

my $env = Scot::Env->new(config_file => './scot.cfg.pl');

my $mets = Scot::Util::Metrics->new(env => $env);

my $epoch = time() - (60 * 60*24*61);
my $dt  = DateTime->from_epoch(epoch => $epoch);
my %r = $mets->get_count_dev("alerts",$dt);
say Dumper(\%r);
