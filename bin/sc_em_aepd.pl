#!/usr/bin/env perl
use warnings;
use strict;
use Daemon::Control;

exit Daemon::Control->new(
    name    => 'SCOT Email Alert Passthrough Daemon (sc_em_aepd)',
    lsb_start   => '$scot',
    lsb_stop    => '',
    lsb_sdesc   => 'SCOT Email Alert Passthrough Processing Daemon',
    lsb_desc    => 'Email Alert Passthrough Processing Daemon ',
    user        => 'scot',
    group       => 'scot',
    program     => '/opt/scot/bin/email_responder.pl',
    program_args => ['AlertPassthrough'],
    pid_file    => '/var/run/sc_em_aepd.pid',
    stderr_file => '/var/log/scot/sc_em_aepd.stderr',
    stdout_file => '/var/log/scot/sc_em_aepd.stdout',
    fork        => 2,
)->run;

