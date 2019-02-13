#!/usr/bin/env perl

use warnings;
use strict;
use v5.18;
use lib '../../lib';

use Data::Dumper;
use Test::More;
use Scot::Env;
use Scot::Factory::Stomp;

my $factory = Scot::Factory::Stomp->new(
    config  => {
        host        => 'localhost',
        post        => 61613,
        destination => '/queue/foo',
    },
);

is (ref($factory), "Scot::Factory::Stomp", "Factory built");

my $product = $factory->make;

is (ref($product), $factory->product, "Build correct product");

done_testing();
exit 0;
