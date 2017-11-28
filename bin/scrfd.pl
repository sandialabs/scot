#!/usr/bin/env perl

use warnings;
use strict;
use Daemon::Control;

# the flairing daemon

exit Daemon::Control->new(
    name    =>  "Scot Reflair Daemon (scrfd)",
    lsb_start   => '$scot',
    lsb_stop    => "",
    lsb_sdesc   => "Scot Reflair Daemon",
    lsb_desc    => "Scot Reflair Daemon finds things to reflair",
    user        => "scot",
    group       => "scot",
    program     => '/opt/scot/bin/reflair.pl',
    program_args    => [],
    pid_file    => "/var/run/scrfd.pid",
    stderr_file => "/var/log/scot/scrfd.stderr",
    stdout_file => "/var/log/scot/scrfd.stdout",
    fork        => 2,
)->run;
