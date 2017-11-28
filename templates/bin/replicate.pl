#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use lib '../../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
use v5.18;
use Scot::App::Replicate;
use Scot::Env;

my $config_file = $ENV{'scot_replicate_config_file'} // '/opt/scot/etc/replicate.cfg.pl';
my $env         = SCOT::Env->new({
    config_file => $config_file
});

my $loop    = Scot::App::Replicate->new( 
    env => $env
);
$loop->run();

