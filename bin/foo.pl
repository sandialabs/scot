#!/usr/bin/env perl

use lib '../lib';
use lib '/opt/scot/bin';
use v5.18;
use Meerkat;
use Scot::Env;

## 
## sample code, on how to iterate over all alerts
##

my $env = Scot::Env->new({
    logfile => "./foo.log",
    mode    => "prod",
});

my $collection = $env->mongo->collection("Alert");

my $cursor  = $collection->find({});

while ( my $alert = $cursor->next ) {
    say "Alert ".$alert->id;
}

