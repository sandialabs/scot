#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::File;

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

my $file  = $mongo->collection("File");
ok (defined $file, "Collection object is defined");

my $file1    = $file->create(
    filename    => "foo.bar.html",
    size        => 10,
    notes       => "blah",
    directory   => "/scotfiles",

);

ok (defined $file1, "file 1 created");
is ($file1->id, 1, "ID is correct");
is ($file1->size, 10, "size is correct");
is ($file1->directory, "/scotfiles", "directory is correct");



done_testing();
exit 0;
