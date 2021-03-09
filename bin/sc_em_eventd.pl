#!/usr/bin/env perl
use warnings;
use strict;
use Daemon::Control;

exit Daemon::Control->new(
    name    => 'SCOT Email Event Processing Daemon (sc_em_eventd)',
    lsb_start   => '$scot',
    lsb_stop    => '',
    lsb_sdesc   => 'SCOT Email Event Processing Daemon',
    lsb_desc    => 'Email Event Processing Daemon polls inboxes for SCOT',
    user        => 'scot',
    group       => 'scot',
    program     => '/opt/scot/bin/email_responder.pl',
    program_args => ['Event'],
    pid_file    => '/var/run/sc_em_eventd.pid',
    stderr_file => '/var/log/scot/sc_em_eventd.stderr',
    stdout_file => '/var/log/scot/sc_em_eventd.stdout',
    fork        => 2,
)->run;

