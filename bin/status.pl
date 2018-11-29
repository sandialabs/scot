#!/usr/bin/env perl

use v5.16;
use lib '../lib';
use Data::Dumper;

my @daemons = (qw(scfd scrfd scepd scot mongod));
my %status  = ();

foreach my $d (@daemons) {

    my $sysctl_output   = `systemctl --no-pager --property=ActiveState show $d`;

    if ( grep { /inactive/i } $sysctl_output ) {
        $status{$d} = "error";
        next;
    }

    if ( grep { /active/i } $sysctl_output ) {
        $status{$d} = "ok";
        next;
    }

    $status{$d} = "warn";
}

my $status_file = "../data/status.txt";

open(my $fh, ">", $status_file) or die "Can not open $status_file for writing.";

foreach my $d (sort keys %status) {
    print $fh "$d=".$status{$d}."\n";
}

close($fh);
