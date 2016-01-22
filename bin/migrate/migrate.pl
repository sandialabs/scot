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


foreach my $arg (@ARGV) {
    say "Migrating $arg...";
    if ( $arg =~ /alert[s]$/ ) {
        $forkmgr->start("migrate_alerts") and next;
        $mover->migrate_alerts(3);
        $forkmgr->finish(0);
    }
    else {
        my $method  = "migrate_".$arg;
        $forkmgr->start($method);
        $mover->$method();
        $forkmgr->finish(0);
    }
}


    
