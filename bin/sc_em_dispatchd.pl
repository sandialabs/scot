#!/usr/bin/env perl
use warnings;
use strict;
use Daemon::Control;

exit Daemon::Control->new(
    name    => 'SCOT Email Dispatch Processing Daemon (sc_em_dispatchd)',
    lsb_start   => '$scot',
    lsb_stop    => '',
    lsb_sdesc   => 'SCOT Email Dispatch Processing Daemon',
    lsb_desc    => 'Email Dispatch Processing Daemon polls inboxes for SCOT',
    user        => 'scot',
    group       => 'scot',
    program     => '/opt/scot/bin/email_responder.pl',
    program_args => ['Dispatch'],
    pid_file    => '/var/run/sc_em_dispatchd.pid',
    stderr_file => '/var/log/scot/sc_em_dispatchd.stderr',
    stdout_file => '/var/log/scot/sc_em_dispatchd.stdout',
    fork        => 2,
)->run;

