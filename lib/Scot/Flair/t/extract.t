#!/usr/bin/env perl

use strict;
use warnings;
use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use Scot::Flair::Extractor;

my $env = Scot::Env->new({config_file => "./test.cfg.pl"});

my $extractor   = Scot::Flair::Extractor->new(env => $env);

