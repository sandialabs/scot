#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '/opt/scot/lib';
use Scot::Env;
use Data::Dumper;

say "--- Starting Mail Ingester ---";

my $config_file = $ENV{'scot__config_file'} // 
                    '/opt/scot/etc/scot.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);

my $mongo   = $env->mongo;
my $statcol = $mongo->collection('Stat');
my @statdocs    = ();

foreach my $colname (qw(incident event alert)) {

    say "Working on $colname";

    my $collection = $mongo->collection(ucfirst($colname));

    my $cursor  = $collection->find({
        created     => { '$lt'  => 1480528800 }
    });

    my $totaldocs   = $cursor->count;
    say "    Processing $totaldocs documents";

    my %stats;
    while ( my $obj = $cursor->next ) {
        my $cdt = DateTime->from_epoch( epoch => $obj->created );
        $statcol->increment($cdt, "$colname created", 1);

    }
}






