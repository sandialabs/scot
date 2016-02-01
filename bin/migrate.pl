#!/usr/bin/env perl

use lib '../../lib';
use Parallel::ForkManager;
use Scot::Env;
use Scot::Controller::Migrate;
use Getopt::Long qw(GetOptions);

use v5.18;

$| = 1;

my $env     = Scot::Env->new({ logfile => "/var/log/scot/migration.log" });
my $mover   = Scot::Controller::Migrate3->new({env=>$env});

my @validcols   = (qw(alert alertgroup event incident entry));

my $colname = $ARGV[0];

unless ( grep {/$colname/} @validcols ) {
    die "Invalid colllection name: $colname.  Valid choices are ".join(',',@validcols);
}

$mover->migrate($colname, { verbose => 1});


    
