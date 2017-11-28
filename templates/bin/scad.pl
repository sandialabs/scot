#!/usr/bin/env perl

use warnings;
use strict;
use Daemon::Control;

# start the scot alert daemon

exit Daemon::Control->new(
    name    =>  "Scot Alert Daemon (scad)",
    lsb_start   => '$scot',
    lsb_stop    => "",
    lsb_sdesc   => "Scot Alert Daemon",
    lsb_desc    => "Scot Alert Daemon inserts Alerts into SCOT",
    user        => "scot",
    group       => "scot",
    program     => '/opt/scot/bin/alert.pl',
    program_args    => [],
    pid_file    => "/var/run/scad.pid",
    stderr_file => "/var/log/scot/scad.stderr",
    stdout_file => "/var/log/scot/scad.stdout",
    fork        => 2,
)->run;
