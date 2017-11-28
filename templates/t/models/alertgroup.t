#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
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

my $alertgroup  = $mongo->collection("Alertgroup");
ok (defined $alertgroup, "Collection object is defined");

my $alertgroup1    = $alertgroup->create(
    message_id      => '6c9eeb6b6160930c65830841c8fe5378@foo.com',
    open_count      => 1,
    closed_count    => 1,
    promoted_count  => 1,
    alert_count     => 3,
    subject         => "Test Subject One",
    parsed          => 0,
    body_html       => qq|<html><table><tr><th>Col1</th><th>Col2</th></tr><tr><td>Foo</td><td>Bar</td></tr></table></html>|,
);

ok (defined $alertgroup1, "alertgroup 1 created");
is ($alertgroup1->id, 1, "ID is correct");
is ($alertgroup1->alert_count, 3, "Alert count is correct");


done_testing();
exit 0;
