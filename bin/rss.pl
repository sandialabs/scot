#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

# use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '/opt/scot/lib';
use Scot::App::Rss;
use Scot::Env;
use Data::Dumper;
use DateTime::Format::Strptime;

$ENV{http_proxy} = 'http://proxy.sandia.gov:80';
$ENV{https_proxy} = 'http://proxy.sandia.gov:80';

say "--- Starting Rss  ---";

my $config_file = $ENV{'scot_app_rss_config_file'} // 
                    '/opt/scot/etc/rss.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);

$env->log->debug("Starting RSS.pl");

my $rss_proc   = Scot::App::Rss->new({
    env => $env,
});

$env->log->debug("Processing...");

$rss_proc->process_feeds();
