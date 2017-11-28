#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::Entity;
use DateTime;

BEGIN {
    use_ok("Meerkat");
};

system("mongo scot-dev ./reset_db.js");

my $mongo   =  Meerkat->new(
    model_namespace         => "Scot::Model",
    collection_namespace    => "Scot::Collection",
    database_name           => "scot-dev",
    client_options          => {
        host        => "mongodb://localhost",
        w           => 1,
        find_master => 1,
    },
);

ok (defined $mongo, "We have a mongo connection");
is (ref($mongo), "Meerkat", "and it is a Meerkat object");

my $dt  = DateTime->now;

my $stat  = $mongo->collection("Stat");
ok (defined $stat, "Collection object is defined");

my $rec = {
    year    => $dt->year,
    month   => $dt->month,
    day     => $dt->day,
    dow     => $dt->dow,
    quarter => $dt->quarter,
    hour    => $dt->hour,
    metric  => "test",
    value   => 1,
};

my $stat1    = $stat->create_from_api($rec);

ok (defined $stat1, "stat 1 created");
is ($stat1->id, 1, "ID is correct");
is ($stat1->year, $dt->year, "year was set correctly");
is ($stat1->month, $dt->month, "month was set correctly");
is ($stat1->hour, $dt->hour, "hour was set correctly");
is ($stat1->value, 1, "value is set correctly");

$stat1 = $stat->increment($dt, "test", 2);
is ($stat1->value, 3, "value was incremented properly");



done_testing();
exit 0;
