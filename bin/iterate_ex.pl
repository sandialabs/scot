#!/usr/bin/env perl

use lib '../lib';
use lib '/opt/scot/bin';
use v5.16;
use Meerkat;
use Scot::Env;

## 
## sample code, on how to iterate over all alerts
##

my $env = Scot::Env->new({
    config_file => "/opt/scot/etc/scot.cfg.pl",
});

my $collection = $env->mongo->collection("Alert");

my $cursor  = $collection->find({});

while ( my $alert = $cursor->next ) {
    say "Alert ".$alert->id;
}

