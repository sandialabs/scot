#!/usr/bin/env perl

use lib '../../../../lib';
use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Scot::Env;
use Scot::Email::Scheduler;

my $config  = "../../../../../Scot-Internal-Modules/etc/email.cfg.pl";
my $env     = Scot::Env->new(config_file => $config);

ok(defined($env), "Scot::Env was created");

my $log = $env->log;

is(ref($log), "Log::Log4perl::Logger", "Logger created");

print Dumper($env->mailboxes);

my $scheduler = Scot::Email::Scheduler->new({
    env => $env
});

ok (defined($scheduler), "Scheduler defined");
is (ref($scheduler), "Scot::Email::Scheduler", "and is right type");

$scheduler->run();


