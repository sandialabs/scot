#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::Handler;

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

my $handler  = $mongo->collection("Handler");
ok (defined $handler, "Collection object is defined");

my $handler1    = $handler->create(
    start   => time(),
    end     => time() + 2600,
    username    => "tbruner",
);

ok (defined $handler1, "handler 1 created");
is ($handler1->id, 1, "ID is correct");
is ($handler1->username, "tbruner", "username is correct");
ok ($handler1->start < $handler1->end, "start is before end");


done_testing();
exit 0;
