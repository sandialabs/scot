#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use lib '../../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::Alertgroup;

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

my $signature  = $mongo->collection("Signature");
ok (defined $signature, "Collection object is defined");

my $signature1    = $signature->create_from_api({
    user    => 'foo',
    name    => 'test signature',
    type    => 'testsig',
    body    => 'foo signatuer text',
});

ok (defined $signature1, "alert 1 created");
is ($signature1->id, 1, "ID is correct");
ok ($signature1->when != 0, "when was set");
ok ($signature1->updated != 0, "updated was set");



done_testing();
exit 0;
