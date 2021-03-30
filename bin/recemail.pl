#!/usr/bin/env perl

use lib '../lib';
use strict;
use warnings;

use Data::Dumper;
use Scot::Env;
use Scot::Email::Scheduler;

my $config  = "../../Scot-Internal-Modules/etc/email.cfg.pl";
my $env     = Scot::Env->new(config_file => $config);

my $sched   = Scot::Email::Scheduler->new({env => $env});
$sched->run();

