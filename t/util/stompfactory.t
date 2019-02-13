#!/usr/bin/env perl

use warnings;
use strict;
use v5.18;
use lib '../../lib';

use Data::Dumper;
use Test::More;
use Scot::Env;
use Scot::Util::StompFactory;

$ENV{'scot_config_file'} = "../../etc/test.cfg.pl";

my $env = Scot::Env->new({config_file => $ENV{'scot_config_file'}});

my $sc = $env->stomp_client;

is (ref($sc), "AnyEvent::STOMP::Client", "factory produces correct object");

done_testing();
exit 0;
