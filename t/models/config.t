#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::Config;

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

my $config  = $mongo->collection("Config");
ok (defined $config, "Collection object is defined");

my $config1    = $config->create(
    module      => "Scot::Foo::Bar",
    item        => {
        key1    => "value1",
        key2    => [ qw(value2 value3) ],
    },
);

ok (defined $config1, "config 1 created");
is ($config1->id, 1, "ID is correct");
ok ($config1->updated != 0, "updated was set");
is ($config1->item->{key1}, "value1", "correct value");



done_testing();
exit 0;
