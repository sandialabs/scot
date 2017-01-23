#!/usr/bin/env perl

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.test.log";
$ENV{'scot_config_paths'}   = '../../../Scot-Internal-Modules/etc';
$ENV{'scot_config_file'}    = 'scot_env_test.cfg';

print "Resetting test db...\n";
system("mongo scot-testing <../../etcsrc/database/reset.js 2>&1 > /dev/null");

use TAP::Harness;
my %args = (
    verbosity   => 1,
);


my $harness = TAP::Harness->new(\%args);
   $harness->runtests(
        './env.t',
        './alertgroup.t',
        './checklist.t',
#        './alert.t',
        './event.t',
        './entry.t',
        './handler.t',
        './intel.t',
        './incident.t',
        './task.t',
#        './flair.t',
        './guide.t',
#        './entity.t',
        './promote.t',
    );
