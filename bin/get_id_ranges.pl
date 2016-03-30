#!/usr/bin/env perl

use lib '../lib';
use Parallel::ForkManager;
use Scot::Env;
use Scot::App::Migrate;
use Getopt::Long qw(GetOptions);

use v5.18;

$| = 1;
# $ENV{'scot_mode'} = "migrated"; # use this to set the scot-foo database
my @validcols   = (qw(alert alertgroup event incident entry handler guide user file));

my $colname = $ARGV[0];
my $multi   = $ARGV[1];

unless ( grep {/$colname/} @validcols ) {
    die "Invalid colllection name: $colname.  Valid choices are ".join(',',@validcols);
}



my $env     = Scot::Env->new({ 
    logfile => "/var/log/scot/migration.$colname.log" 
});
my $mover   = Scot::App::Migrate->new({env=>$env});


my $opts   = {
    verbose => 1,
};
if ( $multi ) {
    $opts->{num_proc}   = $multi;
#    $opts->{idranges}   = [
#        [0  , 18430988],
#        [18430989 , 21987375],
#        [21987376 , 25543744],
#        [25543745 , 39100097],
#    ];
}

my @ranges = $mover->get_id_ranges($colname, $opts->{num_proc}, $opts);

say Dumper(@ranges);


    
