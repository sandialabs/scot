#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '/opt/scot/lib';
use Scot::App::Mail;
use Scot::Env;
use Data::Dumper;

say "--- Starting Mail Ingester ---";

my $config_file = $ENV{'scot_app_alert_config_file'} // 
                    '/opt/scot/etc/alert.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);

my $processor   = Scot::App::Mail->new({
    env => $env,
});
$processor->run();
