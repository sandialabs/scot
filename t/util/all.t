#!/usr/bin/env perl

$ENV{'scot_mode'}           = 'testing';
$ENV{'scot_config_file'}    = '../../etc/test.cfg.pl';

use TAP::Harness;
my %args = ( verbosity => 1 );
my $h    = TAP::Harness->new(\%args);

$h->runtests(qw(
    ./date.t  
    ./geoip.t  
    ./mongoquerymaker.t  
    ./stompfactory.t
));

