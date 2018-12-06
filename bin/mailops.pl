#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use lib '/opt/scot/lib';
use lib '../lib';
use lib '../../Scot-Internal-Modules/lib';
use Scot::App::Mail;
use Scot::Env;
use Data::Dumper;
use DateTime;

# Sample code on how to mark a certain number of days of email messages as unread

my $config_file = $ENV{'scot_mail_config_file'} // '/opt/scot/etc/alert.cfg.pl';
my $env         = Scot::Env->new({
    config_file => $config_file,
});


say "--- Starting Mail Marker ---";

my $processor   = Scot::App::Mail->new({
    env => $env
});

# $processor->mark_all_read();

$processor->mark_some_unread({'day', 3});
