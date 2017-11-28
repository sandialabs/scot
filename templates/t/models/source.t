#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::Source;

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

my $source  = $mongo->collection("Source");
ok (defined $source, "Collection object is defined");

my $source1    = $source->create(
    name      => "foo",
    targets   => [
        { target_type => "bar", target_id => 1 },
        { target_type => "bar", target_id => 2 },
    ],
    occurred    => [time()],
);

ok (defined $source1, "source 1 created");
is ($source1->id, 1, "ID is correct");
ok ($source1->occurred != 0, "occurred was set");
is ($source1->targets->[1]->{target_id}, 2, "target_id is correct value");

done_testing();
exit 0;
