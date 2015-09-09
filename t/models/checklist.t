#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::Checklist;

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

my $checklist  = $mongo->collection("Checklist");
ok (defined $checklist, "Collection object is defined");

my $checklist1    = $checklist->create(
    subject     => "Checklist test 1",
);

ok (defined $checklist1, "checklist 1 created");
is ($checklist1->id, 1, "ID is correct");
ok ($checklist1->updated != 0, "updated was set");
is ($checklist1->subject, "Checklist test 1", "Subject is correct");



done_testing();
exit 0;
