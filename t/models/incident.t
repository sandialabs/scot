#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::Incident;

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

my $incident  = $mongo->collection("Incident");
ok (defined $incident, "Collection object is defined");

my $incident1    = $incident->create(
    occurred    => time(),
    discovered  => time() + 100,
    reported    => time() + 3600,
    subject     => "Incident1",
    status      => "open",
    owner       => "tbruner",
    readgroups  => $env->default_groups->{readgroups},
    modifygroups  => $env->default_groups->{modifygroups},
);

ok (defined $incident1, "incident 1 created");
is ($incident1->id, 1, "ID is correct");



done_testing();
exit 0;
