#!/usr/bin/env perl

use lib '../lib';
use strict;
use warnings;

use Data::Dumper;
use Scot::Env;
use Scot::Email::Scheduler;

my $dry = $ARGV[0];

my $config  = "../../Scot-Internal-Modules/etc/email.cfg.pl";
my $env     = Scot::Env->new(config_file => $config);

my $options = { env => $env };
$options->{dry_run} = 1 if defined $dry;

my $sched   = Scot::Email::Scheduler->new($options);
$sched->run();

