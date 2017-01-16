#!/usr/bin/env perl

use lib '../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Util::Config;
use v5.18;

my $config1     = Scot::Util::Config->new({
    file    => 'config1.cfg',
    paths   => [ './foo/etc', './etc', ],   # last in paths wins
});

my $conf1_href = $config1->get_config;

say Dumper($conf1_href);



