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
    value   => "Foo.com",
    type    => "domain",
    targets => [
        { target_type => "alertgroup", target_id => 1 },
    ],
    classes => [ qw(domain-entity) ],
);

ok (defined $entity1, "entity 1 created");
is ($entity1->id, 1, "ID is correct");
is ($entity1->value, "Foo.com", "value is correct");



done_testing();
exit 0;
