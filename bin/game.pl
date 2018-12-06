#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use lib '../../Scot-Internal-Modules/lib';
# use lib '/opt/scot/lib';
use lib '../lib';
use lib '/opt/scot/lib';
use Scot::App::Game;
use Scot::Env;
use Data::Dumper;

say "--- Starting Game Tally ---";

my $config_file = $ENV{'scot_game_config_file'} // '/opt/scot/etc/game.cfg.pl';

my $env = Scot::Env->new({
    config_file => $config_file,
});

my $processor   = Scot::App::Game->new({
    env => $env,
});
$processor->run();
