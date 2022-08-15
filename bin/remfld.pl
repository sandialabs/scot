#!/usr/bin/env perl

use warnings;
use strict;
use Daemon::Control;

# the remote flair daemon

exit Daemon::Control->new(
    name    =>  "SCOT Remote Flair Proxy Daemon (remfld.pl)",
    lsb_start   => '$scot',
    lsb_stop    => "",
    lsb_sdesc   => "Scot Remote Flair Proxy Daemon",
    lsb_desc    => "Scot Remote Flair Proxy Daemon proxies RF",
    user        => "scot",
    group       => "scot",
    program     => '/opt/scot/bin/remoteflair.pl',
    program_args    => [],
    pid_file    => "/var/run/remfld.pid",
    stderr_file => "/var/log/scot/remfld.stderr",
    stdout_file => "/var/log/scot/remfld.stdout",
    fork        => 2,
)->run;
