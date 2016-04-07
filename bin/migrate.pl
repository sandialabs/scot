#!/usr/bin/env perl

use lib '../lib';
use Parallel::ForkManager;
use Scot::Env;
use Scot::App::Migrate;
use Getopt::Long qw(GetOptions);
use Data::Dumper;
use Log::Log4perl::Level;

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
    logfile  => "/var/log/scot/migration.$colname.log" ,
    log_level => "$DEBUG",
});
my $mover   = Scot::App::Migrate->new({env=>$env});


my $opts   = {
    verbose => 1,
};
if ( $multi ) {
    $opts->{num_proc}   = $multi;
#    $opts->{idranges}   = [
#        [977857  , 18679217],
#        [18679218 , 22587483],
#        [22587484 , 26495731],
#        [26495732 , 30403965],
#    ];
    if ( $colname eq "alert" ) {
        $opts->{idranges}   = [
            [ 1, 17953577 ],
            [ 17953578, 22103723 ],
            [ 22103724, 26253851 ],
            [ 26253852, 30403965 ],
        ];
    }
}

$mover->migrate($colname, $opts);


    
