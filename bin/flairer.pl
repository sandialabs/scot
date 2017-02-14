#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use lib '../../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
use v5.18;
use Scot::App::Flair;

my $config_file = $ENV{'scot_app_flair_config_file'} //
                        '/opt/scot/etc/flair.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);

my $loop    = Scot::App::Flair->new({ 
    env => $env,
});
$loop->run();

