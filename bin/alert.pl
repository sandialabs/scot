#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use Scot::Controller::Mail;
use Scot::Env;
use Data::Dumper;

my $env         = Scot::Env->new();
my $processor   = Scot::Controller::Mail();
$processor->run();
