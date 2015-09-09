#!/usr/bin/env perl

$ENV{'scot_mode'}   = "testing";
system("../bin/reset_db.js");

use TAP::Harness;
my %args = (
    verbosity   => 1,
);


my $harness = TAP::Harness->new(\%args);
   $harness->runtests(
        './alertgroup.t',
#        './alert.t',
#        './event.t',
#        './entry.t',
#        './incident.t',
#        './task.t',
#        './flair.t',
#        './guide.t',
#        './entity.t',
#        './promote.t',
    );
