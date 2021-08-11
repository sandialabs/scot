#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

# use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '/opt/scot/lib';
use Scot::App::Topdomains;
use Scot::Env;
use Data::Dumper;

say "--- Starting Topdomains  ---";

my $config_file = $ENV{'scot_app_scot_config_file'} // 
                    '/opt/scot/etc/scot.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);

$env->log->debug("Starting topdomains.pl");

my $proc   = Scot::App::Topdomains->new({
    env => $env,
});

$env->log->debug("Processing...");

$proc->run();

