#!/usr/bin/env perl

use lib '../lib';
use lib '/opt/scot/lib';
use strict;
use warnings;

use Data::Dumper;
use Scot::Env;
use Scot::Email::Scheduler;

my $dry = $ARGV[0];
my $pidfile = '/var/run/inbox.pid';

if ( -s $pidfile ) {
    die "$pidfile exists. Kill running $0 and delete $pidfile to continue";
}

open my $pidfh, ">", $pidfile or die "Unable to create PID file $pidfile!";
print $pidfh "$$";
close $pidfh;

# my $config  = "../../Scot-Internal-Modules/etc/email.cfg.pl";
my $config  = "/opt/scot/etc/inbox.cfg.pl";
my $env     = Scot::Env->new(config_file => $config);

my $options = { env => $env };
$options->{dry_run} = 1 if defined $dry;

my $sched   = Scot::Email::Scheduler->new($options);
$sched->run();

system("rm -f $pidfile");
