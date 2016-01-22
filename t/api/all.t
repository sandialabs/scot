#!/usr/bin/env perl

$ENV{'scot_mode'}   = "testing";
system("../../bin/database/reset.js");

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
