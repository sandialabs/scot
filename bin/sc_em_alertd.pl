#!/usr/bin/env perl
use warnings;
use strict;
use Daemon::Control;

exit Daemon::Control->new(
    name    => 'SCOT Email Alert Processing Daemon (sc_em_alertd)',
    lsb_start   => '$scot',
    lsb_stop    => '',
    lsb_sdesc   => 'SCOT Email Alert Processing Daemon',
    lsb_desc    => 'Email Alert Processing Daemon polls inboxes for SCOT',
    user        => 'scot',
    group       => 'scot',
    program     => '/opt/scot/bin/email_responder.pl',
    program_args => ['Alert'],
    pid_file    => '/var/run/sc_em_alertd.pid',
    stderr_file => '/var/log/scot/sc_em_alertd.stderr',
    stdout_file => '/var/log/scot/sc_em_alertd.stdout',
    fork        => 2,
)->run;

