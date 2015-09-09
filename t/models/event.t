#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::Entry;

BEGIN {
    use_ok("Meerkat");
    use_ok("Scot::Env");
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

my $env = Scot::Env->new();

ok (defined $mongo, "We have a mongo connection");
is (ref($mongo), "Meerkat", "and it is a Meerkat object");

my $entry  = $mongo->collection("Entry");
ok (defined $entry, "Collection object is defined");

my $entry1    = $entry->create(
    target_type => "event",
    target_id   => 1,
    readgroups  => $env->default_groups->{readgroups},
    modifygroups=> $env->default_groups->{modifygroups},
    body        => "Entry body 1. yeehaw.",
);

ok (defined $entry1, "entry 1 created");
is ($entry1->id, 1, "ID is correct");
ok ($entry1->when != 0, "when was set");
ok ($entry1->updated != 0, "updated was set");
is ($entry1->body, "Entry body 1. yeehaw.", "body is correct");



done_testing();
exit 0;
