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

my $alert  = $mongo->collection("Alert");
ok (defined $alert, "Collection object is defined");

my $alert1    = $alert->create(
    alertgroup  => 1,
    status      => 'open',
    parsed      => 0,
    data        => { 'col1' => "row one", col2 => "column two", col3 => 1 },
);

ok (defined $alert1, "alert 1 created");
is ($alert1->id, 1, "ID is correct");
ok ($alert1->when != 0, "when was set");
ok ($alert1->updated != 0, "updated was set");



done_testing();
exit 0;
