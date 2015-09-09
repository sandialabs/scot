#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::Tag;

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

my $tag  = $mongo->collection("Tag");
ok (defined $tag, "Collection object is defined");

my $tag1    = $tag->create(
    text    => "tag1",
    tagees  => [ { type => "event", id => 1 } ],
    occurred    => [ time() ],
);

ok (defined $tag1, "tag 1 created");
is ($tag1->id, 1, "ID is correct");
ok ($tag1->occurred->[0] != 0, "occurred is correct");
is ($tag1->text, "tag1", "text is correct");



done_testing();
exit 0;
