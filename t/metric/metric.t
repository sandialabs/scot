#!/usr/bin/env perl

use lib '../../lib';
use Scot::Util::Metrics;
use Scot::Env;
use Data::Dumper;
use v5.18;

my $env = Scot::Env->new(config_file => './scot.cfg.pl');

my $mets = Scot::Util::Metrics->new(env => $env);

my $epoch = time() - (60 * 60*24*30);

my %r = $mets->get_created_stats($epoch, "day");
say Dumper(\%r);
%r = ();

%r = $mets->get_created_stats($epoch, "month");
say Dumper(\%r);
%r = ();

%r = $mets->get_created_stats($epoch, "year");
say Dumper(\%r);

