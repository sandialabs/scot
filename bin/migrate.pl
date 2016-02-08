#!/usr/bin/env perl

use lib '../lib';
use Parallel::ForkManager;
use Scot::Env;
use Scot::Controller::Migrate;
use Getopt::Long qw(GetOptions);

use v5.18;

$| = 1;

my $env     = Scot::Env->new({ logfile => "/var/log/scot/migration.log" });
my $mover   = Scot::Controller::Migrate->new({env=>$env});

my @validcols   = (qw(alert alertgroup event incident entry handler guide user file));

my $colname = $ARGV[0];
my $multi   = $ARGV[1];

unless ( grep {/$colname/} @validcols ) {
    die "Invalid colllection name: $colname.  Valid choices are ".join(',',@validcols);
}

my $opts   = {
    verbose => 1,
};
if ( $multi ) {
    $opts->{multi_proc_alerts}++;
    $opts->{idranges}   = [
        [1081605  , 18430988],
        [18430989 , 21987375],
        [21987376 , 25543744],
        [25543745 , 29100097],
    ];
}

$mover->migrate($colname, $opts);


    
