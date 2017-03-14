#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';
use lib '../../lib';

use Test::More;
use Test::Deep;
use Scot::Env;
use Data::Dumper;
use v5.18;

my $configfile  = 'scot_env.cfg';
my $env     = Scot::Env->new(
    config_file => "../../../Scot-Internal-Modules/etc/scot.test.cfg.pl",
);


ok(defined($env), "Env is defined");
is($env->servername, "127.0.0.1", "Servername set correctly");
is($env->group_mode, "ldap", "Group Mode Set correctly");


done_testing();



