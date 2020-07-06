#!/usr/bin/env perl

use warnings;
use strict;
use Daemon::Control;

# the recorded future proxy  daemon

exit Daemon::Control->new(
    name    =>  "SCOT Recorded Future Proxy Daemon (recfpd.pl)",
    lsb_start   => '$scot',
    lsb_stop    => "",
    lsb_sdesc   => "Scot Recorded Future Proxy Daemon",
    lsb_desc    => "Scot Recorded Future Proxy Daemon proxies RF",
    user        => "scot",
    group       => "scot",
    program     => '/opt/scot/bin/rfproxy.pl',
    program_args    => [],
    pid_file    => "/var/run/recfpd.pid",
    stderr_file => "/var/log/scot/recfpd.stderr",
    stdout_file => "/var/log/scot/recfpd.stdout",
    fork        => 2,
)->run;
