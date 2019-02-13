#!/usr/bin/env perl

use warnings;
use strict;
use v5.18;
use lib '../../lib';

use Data::Dumper;
use Test::More;
use Scot::Env;
use Scot::Factory::Mongo;

my $factory = Scot::Factory::Mongo->new(
    config  => {
        db_name         => 'scot-testing',
        host            => 'mongodb://localhost',
        write_safety    => 1,
        find_master     => 1,
    },
);

is (ref($factory), "Scot::Factory::Mongo", "Factory built");

my $product = $factory->make;

is (ref($product), $factory->product, "Build correct product");

done_testing();
exit 0;
