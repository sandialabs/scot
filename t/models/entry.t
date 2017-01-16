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

my $entity  = $mongo->collection("Entity");
ok (defined $entity, "Collection object is defined");

my $entity1    = $entity->create(
    value     => "foo",
    type      => "something",
    targets   => [
        { target_type => "bar", target_id => 1 },
        { target_type => "bar", target_id => 2 },
    ],
    occurred    => [time()],
    classes     => [ qw(foo bar) ],
);

ok (defined $entity1, "entity 1 created");
is ($entity1->id, 1, "ID is correct");
ok ($entity1->occurred != 0, "occurred was set");
is ($entity1->targets->[1]->{target_id}, 2, "target_id is correct value");
is ($entity1->classes->[1], "bar", "classes[1] is correct");



done_testing();
exit 0;
