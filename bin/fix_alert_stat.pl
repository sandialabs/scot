#!/usr/bin/env perl

use lib '../lib';
use lib '/opt/scot/lib';
use Data::Dumper;
use Scot::Env;
use v5.18;

my $env   = Scot::Env->new(config_file=>'/opt/scot/etc/scot.cfg.pl');
my $mongo = $env->mongo;
my $statcol = $mongo->collection('Stat');
my $agcol   = $mongo->collection('Alertgroup');

my $epoch   = time();
my $yago    = $epoch - (365 * 24 * 3600);

my $cursor  = $agcol->find({created => { '$lte' => $epoch, '$gte' => $yago }});

while ( my $obj = $cursor->next ) {
    my $alert_count = $obj->alert_count;
    if ($alert_count == 0) {
        say "OOOPS.  We have a zero alert_count ".Dumper($obj->as_hash);
    }
    $statcol->fix_stat('alert created', $alert_count, $obj->created);
}
