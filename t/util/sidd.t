#!/usr/bin/env perl

use warnings;
use strict;
use v5.18;
use lib '../../lib';

use Test::More;
use Scot::Env;
use Scot::Util::Sidd;
use Data::Dumper;

my $env     = Scot::Env->new();
my $sidd    = Scot::Util::Sidd->new({
    env         => $env,
    servername  => 'sidd.sandia.gov',
    username    => 'scot',
    password    => '3mIn8g$doliq*7qIS-suopu88',
});

my $href    = $sidd->get_data("domain", "401k.com");
say Dumper($href);

my $href    = $sidd->get_data("domain", "apture.com");
say Dumper($href);
my @identifiers = $sidd->list_identifiers_of_type('domain',10);
say Dumper(@identifiers);


