#!/usr/bin/env perl
use warnings;
use strict;
use Daemon::Control;

exit Daemon::Control->new(
    name    => 'SCOT Email Processing Daemon (sc_emaild)',
    lsb_start   => '$scot',
    lsb_stop    => '',
    lsb_sdesc   => 'SCOT Email Processing Daemon',
    lsb_desc    => 'Email Processing Daemon polls inboxes for SCOT',
    user        => 'scot',
    group       => 'scot',
    program     => '/opt/scot/bin/email_processor.pl',
    program_args => [],
    pid_file    => '/var/run/sc_emaild.pid',
    stderr_file => '/var/log/scot/sc_emaild.stderr',
    stdout_file => '/var/log/scot/sc_emaild.stdout',
    fork        => 2,
)->run;

