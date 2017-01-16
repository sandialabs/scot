#!/usr/bin/env perl

use TAP::Harness;
my %args    = ( verbosity   => 1 );

my $harness = TAP::Harness->new(\%args);

$harness->runtests(qw(
    ./alertgroup.t
    ./alert.t
    ./audit.t
    ./checklist.t
    ./config.t
    ./entity.t
    ./entry.t
    ./event.t
    ./file.t
    ./guide.t
    ./handler.t
    ./incident.t
    ./intel.t
    ./module.t
    ./source.t
    ./tag.t
    ./user.t
));
    
