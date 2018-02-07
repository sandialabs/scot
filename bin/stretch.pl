#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use lib '../../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
use v5.18;
use Scot::App::Responder::Stretch;
use IO::Prompt;
use Getopt::Long qw(GetOptions);

# put things into elastic 

my $config_file  = "/opt/scot/etc/stretch.cfg.pl";
my $startepoch;
my $endepoch;
my $collection;
my $limit       = 0;
my $all;
my $id  = 0;
my $start;
my $end;

GetOptions(
    'l=i'       => \$limit,
    'col=s'     => \$collection,
    'a'         => \$all,
    'id=s'      => \$id,
    'rs=s'      => \$start,
    're=s'      => \$end,
) or die <<EOF

Invalid option!

    usage: $0
        [-l=100]            limit to 100 items
        [-col=collection]   process collection 
        [-a]                all
        [-rs m-d-yyyy]      date range reprocess start 
        [-re m-d-yyyy]      date range reprocess end
EOF
;

my $env = Scot::Env->new(
    config_file => $config_file,
);


my $loop    = Scot::App::Responder::Stretch->new( 
    env => $env,
);


if ( $all ) {
    $loop->process_all($collection,$id+0);
}
elsif ( defined $start  and defined $end ) {
    my ($sm,$sd,$sy) = split(/-/,$start);
    my $startdt = DateTime->new(
        year    => $sy,
        month   => $sm,
        day     => $sd,
        hour    => 0,
        minute  => 0,
        second  => 0,
    );
    my ($em,$ed,$ey) = split(/-/,$end);
    my $enddt = DateTime->new(
        year    => $ey,
        month   => $em,
        day     => $ed,
        hour    => 0,
        minute  => 0,
        second  => 0,
    );
    my $endepoch    = $enddt->epoch;
    my $startepoch  = $startdt->epoch;
    $loop->process_by_date($collection, $startepoch, $endepoch);
}
else {
    $loop->run();
}

