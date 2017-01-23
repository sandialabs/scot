#!/usr/bin/env perl

use lib '../../lib';

use Test::More;
use Test::Deep;
use Scot::Env;
use Data::Dumper;
use v5.18;


my $configfile  = 'scot_env.cfg';
my $paths       = [ qw(./configs) ];

my $env     = Scot::Env->new(
    config_file              => $configfile,
    paths                    => $paths,
);


ok(defined($env), "Env is defined");

is($env->servername, "scottestserver", "Servername set correctly");


done_testing();



