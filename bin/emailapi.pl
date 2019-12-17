#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '/opt/scot/lib';
use Scot::App::EmailApi;
use Scot::Env;
use Data::Dumper;

say "--- Starting Mail Ingester ---";

my $config_file = $ENV{'scot_app_emailapi_config_file'} // 
                    '/opt/scot/etc/emailapi.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);

# say Dumper($env);

my $processor   = Scot::App::EmailApi->new({
    env => $env,
});
$processor->run();
