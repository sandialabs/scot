#!/usr/bin/env perl

use warnings;
use strict;
use Daemon::Control;

# start the process that adds to elastic search

exit Daemon::Control->new(
    name    =>  "Scot ElasticSearch Push Daemon (scepd)",
    lsb_start   => '$scot',
    lsb_stop    => "",
    lsb_sdesc   => "Scot ElasticSearch Push Daemon",
    lsb_desc    => "Scot ElasticSearch Push Daemon inserts SCOT data into ES",
    user        => "scot",
    group       => "scot",
    program     => '/opt/scot/bin/stretch.pl',
    program_args    => [],
    pid_file    => "/var/run/scepd.pid",
    stderr_file => "/var/log/scot/scepd.stderr",
    stdout_file => "/var/log/scot/scepd.stdout",
    fork        => 2,
)->run;
