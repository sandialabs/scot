#!/usr/bin/env perl

use TAP::Harness;
my %args = (
    verbosity   => 1,
);

unless ( -x '../scot.conf' ) {
    system('../bin/update_conf.pl .. development');
}

my $harness = TAP::Harness->new(\%args);
   $harness->runtests(
        './conf.t',
        './alert.t',
        './alertgroup.t',
        './event.t',
        './entry.t',
        './incident.t',
        './task.t',
        './flair.t',
        './guide.t',
        './entity.t',
        './promote.t',
    );
