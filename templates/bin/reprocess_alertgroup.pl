#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use lib '../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
use Scot::App::Mail;
use Scot::Env;
use Data::Dumper;

# sample code on how to reprocess an alertgroup for flair
# ./reprocess_alertgroup.pl 123


say "--- Starting Mail Reprocessor ---";

my $config_file = $ENV{'scot_mail_config_file'} // '/opt/scot/etc/alert.cfg.pl';
my $env         = Scot::Env->new({
    config_file => $config_file
});

my $processor   = Scot::App::Mail->new({
    env => $env,
});

my $id = $ARGV[0];
$processor->reprocess_alertgroup($id);
