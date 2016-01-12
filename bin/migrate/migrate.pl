#!/usr/bin/env perl

use lib '../../lib';
use Parallel::ForkManager;
use Scot::Env;
use Scot::Controller::Migrate;
use Getopt::Long qw(GetOptions);

use v5.18;

$| = 1;

my $env     = Scot::Env->new({ logfile => "/var/log/scot/migration.log" });
my $mover   = Scot::Controller::Migrate->new({env=>$env});

my $do_alertgroups  = 1;
my $do_alerts       = 1;
my $do_events       = 1;
my $do_incidents    = 1;
my $do_entries      = 1;

GetOptions(
    "alertgroups"   => sub { $do_alertgroups = 0 },
    "alerts"        => sub { $do_alerts = 0 },
    "events"        => sub { $do_events = 0},
    "incidents"     => sub { $do_incidents = 0},
    "entries"       => sub { $do_entries = 0},
) or die <<EOF;

Usage: $0
    -alertgroups        do not migrate alertgroups
    -alerts             do not migrate alerts
    -events             do not migrate events
    -incidents          do not migrate incidents
    -entries            do not migrate entries

EOF

my $forkmgr = Parallel::ForkManager->new(5);

$forkmgr->run_on_start(
    sub {
        my ($pid, $ident) = @_;
        say "[PID $pid] Migrating $ident";
    }
);

$forkmgr->run_on_wait(
    sub {
        say "Workers are still working...";
    }
);

$forkmgr->run_on_finish(
    sub {
        my ($pid, $exit, $ident) = @_;
        say "[PID $pid] $ident migration finished";
    }
);

my @methods = ();


    
if ( $do_alertgroups > 0 ) {
    push @methods, "migrate_alertgroups";
}

if ( $do_alerts > 0 ) {
    push @methods, "migrate_alerts";
}

if ( $do_events > 0 ) {
    push @methods, "migrate_events";
}

if ( $do_incidents > 0 ) {
    push @methods, "migrate_incidents";
}

if ( $do_entries > 0 ) {
    push @methods, "migrate_entries";
}

foreach my $method (@methods) {
    $forkmgr->start($method) and next;
    $mover->$method();
    $forkmgr->finish(0);
}
