#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use lib '../../Scot-Internal-Modules/lib';
# use lib '/opt/scot/lib';
use lib '../lib';
use lib '/opt/scot/lib';
use Scot::App::Game;
use Scot::Env;
use Data::Dumper;

say "--- Starting Game Tally ---";

my $config_file = $ENV{'scot_game_config_file'} // '/opt/scot/etc/game.cfg.pl';

#$SIG{__DIE__} = sub { our @reason = @_ };
#
#END {
#    our @reason;
#    if (@reason) {
#        say "Game died because: @reason";
#        $env->log->error("Game died because: ",{filter=>\&Dumper, value=>\@reason});
#    }
#}


my $env = Scot::Env->new({
    config_file => $config_file,
});

my $processor   = Scot::App::Game->new({
    env => $env,
});
$processor->docker();
