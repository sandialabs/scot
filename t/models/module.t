#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::Module;

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
is (ref($mongo), "Meerkat", "and it is a Meercat object");

my $loadmod  = $mongo->collection("Module");
ok (defined $loadmod, "Collection object is defined");

my $module_1    = $loadmod->create(
    class       => "Scot::Util::Activemq",
    attribute   => "activemq",
);

ok (defined $module_1, "Load module 1 created");
is ($module_1->id, 1, "ID is correct");
is ($module_1->class, "Scot::Util::Activemq", "Class is correct");
is ($module_1->attribute, "activemq", "Attribute name is correct");

my $module_2    = $loadmod->create(
    class       => "Scot::Util::Activemq",
    attribute   => "activemq",
);

ok (defined $module_2, "Load module 2 created");
is ($module_2->id, 2, "ID is correct");
is ($module_2->class, "Scot::Util::Activemq", "Class is correct");
is ($module_2->attribute, "activemq", "Attribute name is correct");


done_testing();
exit 0;
