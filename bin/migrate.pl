#!/usr/bin/env perl

use lib '../lib';
use Parallel::ForkManager;
use Scot::Env;
use Scot::App::Migrate2;
use Getopt::Long qw(GetOptions);
use Data::Dumper;
use Log::Log4perl::Level;

use v5.18;

$| = 1;
# $ENV{'scot_mode'} = "migrated"; # use this to set the scot-foo database
my @validcols   = (qw(alertgroup event incident entry handler guide user file));

my $colname = $ARGV[0];
my $multi   = $ARGV[1];

unless ( grep {/$colname/} @validcols ) {
    die "Invalid colllection name: $colname.  Valid choices are ".join(',',@validcols);
}



my $env     = Scot::Env->new({ 
    logfile  => "/var/log/scot/migration.$colname.log" ,
    log_level => "$DEBUG",
});
my $mover   = Scot::App::Migrate2->new({env=>$env});


my $opts   = {
    verbose => 1,
};

say "!!!! Migrating the $colname Collection ";

$mover->migrate($colname, $opts);


    
