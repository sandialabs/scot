#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::Audit;

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

my $audit  = $mongo->collection("Audit");
ok (defined $audit, "Collection object is defined");

my $audit1    = $audit->create(
    who     => "foo",
    what    => "something",
    data    => { pre => "bar", post => "Boom" },
);

ok (defined $audit1, "audit 1 created");
is ($audit1->id, 1, "ID is correct");
ok ($audit1->when != 0, "when was set");
is ($audit1->data->{post}, "Boom", "correct value");



done_testing();
exit 0;
