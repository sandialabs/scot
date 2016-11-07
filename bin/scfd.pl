#!/usr/bin/env perl

use warnings;
use strict;
use Daemon::Control;

# the flairing daemon

exit Daemon::Control->new(
    name    =>  "Scot Flair Daemon (scfd)",
    lsb_start   => '$scot',
    lsb_stop    => "",
    lsb_sdesc   => "Scot Flair Daemon",
    lsb_desc    => "Scot Flair Daemon Flairs SCOT data",
    user        => "scot",
    group       => "scot",
    program     => '/opt/scot/bin/flairer.pl',
    program_args    => [],
    pid_file    => "/var/run/scfd.pid",
    stderr_file => "/var/log/scot/scfd.stderr",
    stdout_file => "/var/log/scot/scfd.stdout",
    fork        => 2,
)->run;
