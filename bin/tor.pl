#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use lib '../lib';
use Scot::Controller::Tor;
use Scot::Env;
use Data::Dumper;

my $env         = Scot::Env->new();
my $processor   = Scot::Controller::Tor->new();
$processor->run();
