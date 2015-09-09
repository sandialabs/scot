#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::User;

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

my $user  = $mongo->collection("User");
ok (defined $user, "Collection object is defined");

my $user1    = $user->create(
    username    => "tbruner",
    pwhash      => "adsfasdfasdf",
    fullname    => "Todd Bruner",
    directory   => "/scotusers",

);

ok (defined $user1, "user 1 created");
is ($user1->id, 1, "ID is correct");
is ($user1->username, "tbruner", "username is correct");



done_testing();
exit 0;
