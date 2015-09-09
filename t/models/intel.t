#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::Intel;


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

my $intel  = $mongo->collection("Intel");
ok (defined $intel, "Collection object is defined");

my $intel1    = $intel->create(
    subject     => "Intel 1",
    owner       => "tbruner",
    readgroups  => $env->default_groups->{readgroups},
    modifygroups  => $env->default_groups->{modifygroups},
);

ok (defined $intel1, "intel 1 created");
is ($intel1->id, 1, "ID is correct");
is ($intel1->subject, "Intel 1", "subject is correct");
ok ($intel1->when != 0, "when is set");



done_testing();
exit 0;
