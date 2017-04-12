#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use lib '../../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
use v5.18;
use Scot::App::Stretch;
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

GetOptions(
    'l=i'       => \$limit,
    'col=s'     => \$collection,
    'a'         => \$all,
    'id=s'      => \$id,
) or die <<EOF

Invalid option!

    usage: $0
        [-l=100]            limit to 100 items
        [-col=collection]   process collection 
        [-a]                all
EOF
;




my $env = Scot::Env->new(
    config_file => $config_file,
);


my $loop    = Scot::App::Stretch->new( 
    env => $env,
);


if ( $all ) {
    $loop->process_all($collection,$id+0);
}
else {
    $loop->run();
}

