#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use lib '../../Scot-Internal-Modules/lib';
# use lib '/opt/scot/lib';
use lib '../lib';
use Scot::App::Game;
use Scot::Env;
use Data::Dumper;

say "--- Starting Game Tally ---";

my $processor   = Scot::App::Game->new({
    configuration_file         => "game.app.cfg",
});
$processor->run();
