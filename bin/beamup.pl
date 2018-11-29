#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use lib '../../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
use v5.16;
use Scot::App::Responder::BeamUp;
use Scot::Env;

my $config_file = $ENV{'scot_beamup_config_file'} // 
    '/opt/scot/etc/beamup.cfg.pl';
my $env         = Scot::Env->new({
    config_file => $config_file
});

my $loop    = Scot::App::Responder::BeamUp->new( 
    env => $env
);
$loop->run();

