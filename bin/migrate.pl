#!/usr/bin/env perl

use lib '../lib';
use lib '/opt/scot/lib';
use Parallel::ForkManager;
use Scot::Env;
use Scot::App::Migrate;
use Getopt::Long qw(GetOptions);
use Data::Dumper;
use Log::Log4perl::Level;

use v5.16;

$| = 1;
# $ENV{'scot_mode'} = "migrated"; # use this to set the scot-foo database
my @validcols   = (qw(alertgroup event incident entry handler guide user file all));

my $colname = $ARGV[0];
my $multi   = $ARGV[1];

unless ( grep {/$colname/} @validcols ) {
    die "Invalid colllection name: $colname.  Valid choices are ".
        join(',',@validcols);
}




my $env     = Scot::Env->new({config_file => '/opt/scot/etc/migrate.cfg.pl' });
my $mover   = Scot::App::Migrate->new({env=>$env});


my $opts   = {
    verbose => 1,
};

if ($colname eq "all") {
    foreach my $collection (@validcols) {
        next if ($collection eq "all");
        say " --- Migrating $collection --- ";
        $mover->migrate($collection, $opts);
    }
    exit 0;
}

say "!!!! Migrating the $colname Collection ";

$mover->migrate($colname, $opts);


    
