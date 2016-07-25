#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use lib '../lib';
use lib '../../Scot-Internal-Modules/lib';
use Scot::App::Mail;
use Scot::Env;
use Data::Dumper;

say "--- Starting Mail Ingester ---";

my $processor   = Scot::App::Mail->new({
    configuration_file         => "mail.app.cfg",
    interactive                 => "yes",
});
$processor->run();
