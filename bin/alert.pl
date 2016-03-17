#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use lib '../lib';
use Scot::App::Mail;
use Scot::Env;
use Data::Dumper;

my $env         = Scot::Env->new({
    logfile     => '/var/log/scot/alert.log',
    authtype    => 'Remoteuser',
    servername  => 'as3001snllx',
});

$env->log->warn("Starting $0");
my $processor   = Scot::App::Mail->new({
    interactive => "yes",
});
$processor->run();
