#!/usr/bin/env perl

use TAP::Harness;
my %args = ( verbosity => 1 );
my $harness = TAP::Harness->new(\%args);

$harness->runtests(
    qw(
        ./table.t
        ./email.t
        ./domain-ip.t
        ./weird.t
        ./event_8610_333009.t
        ./broken-html.t
        ./ip.t
        ./ip-2.t
        ./ip-3.t
        ./anchor.t
    )
);

