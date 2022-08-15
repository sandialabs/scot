#!/usr/bin/env perl

use strict;
use warnings;
use lib '../../../../lib';

use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use Meerkat;
use Log::Log4perl;
use Scot::Flair3::Engine;
use feature qw(say);

my %RESULTS = ();
my $LIMIT   = 30;

my $log = Log::Log4perl->get_logger('flair_test');
my $pattern = "%d %7p [%P] %15F{1}: %4L %m%n";
my $layout  = Log::Log4perl::Layout::PatternLayout->new($pattern);
my $appender= Log::Log4perl::Appender->new(
    'Log::Log4perl::Appender::File',
    name        => 'flair_log',
    filename    => '/var/log/scot/test.log',
    autoflush   => 1,
    utf8        => 1,
);
$appender->layout($layout);
$log->add_appender($appender);
$log->level("DEBUG");
# $log->level("TRACE");

my $prodmongo   = Meerkat->new(
    model_namespace         => 'Scot::Model',
    collection_namespace    => 'Scot::Collection',
    database_name           => 'scot-prod',
    client_options          => {
        host        => 'mongodb://localhost',
        w           => 1,
        find_master => 1,
        socket_timeout_ms => 600000,
    }
);

my $testmongo   = Meerkat->new(
    model_namespace         => 'Scot::Model',
    collection_namespace    => 'Scot::Collection',
    database_name           => 'scot-prod',
    client_options          => {
        host        => 'mongodb://localhost',
        w           => 1,
        find_master => 1,
        socket_timeout_ms => 600000,
    }
);

my $queue   = "/queue/flairtest";
my $topic   = "/topic/scottest";

my $iopackage   = "Scot::Flair3::Io";
require_ok($iopackage);
my $io  = Scot::Flair3::Io->new(
    log     => $log,
    mongo   => $prodmongo,
    queue   => $queue,
    topic   => $topic,
);
ok(defined $io, "io initialized");

require_ok("Scot::Flair3::Imgmunger");
my $imgmunger = Scot::Flair3::Imgmunger->new(io => $io);

my $engine  = Scot::Flair3::Engine->new(io => $io, imgmunger => $imgmunger);
my $udengine = Scot::Flair3::Engine->new(io => $io, imgmunger => $imgmunger, selected_regex_set => 'userdef');

my $env = Scot::Env->new({config_file => './test.cfg.pl'});

compare_alertgroups();
compare_entries();
dump_results();
done_testing;

sub dump_results {
    # say Dumper(\%RESULTS);
    my $ttf = $RESULTS{Alertgroup}{totals}{total} + $RESULTS{Entry}{totals}{total};
    my $tct = $RESULTS{Alertgroup}{total}{core} + $RESULTS{Entry}{totals}{core};
    my $tut = $RESULTS{Alertgroup}{total}{udef} + $RESULTS{Entry}{totals}{udef};
    say "-----------------------";
    say "REPORT";
    say "   Total Time Flair: $ttf";
    say "   Total CORE Time : $tct";
    say "   Total UDEF Time : $tut";
    say "   Missing Entities: " if (defined $RESULTS{missing});
    foreach my $c (keys %{ $RESULTS{missing} }) {
        foreach my $id (keys %{ $RESULTS{missing}{$c} } ) {
            foreach my $t (keys %{ $RESULTS{missing}{$c}{$id} } ) {
                foreach my $e (keys %{ $RESULTS{missing}{$c}{$id}{$t} } ) {
                    printf "        %10s %10d   %20s  %40s\n", $c, $id, $t, $e;
                }
            }
        }
    }
    say "   Extra   Entities: " if (defined $RESULTS{extras});
    foreach my $c (keys %{ $RESULTS{extras} }) {
        foreach my $id (keys %{ $RESULTS{extras}{$c} } ) {
            foreach my $t (keys %{ $RESULTS{extras}{$c}{$id} } ) {
                foreach my $e (keys %{ $RESULTS{extras}{$c}{$id}{$t} } ) {
                    printf "        %10s %10d   %20s  %40s\n", $c, $id, $t, $e;
                }
            }
        }
    }
}

sub compare_alertgroups {
    my $alertgroup_total_time = $io->get_timer("Alertgroup_total_time");
    my $cursor                = get_alertgroup_cursor();

    while (my $ag = $cursor->next) {
        test_alertgroup($ag);
    }

    my $elapsed = &$alertgroup_total_time;
    $log->info("++++ Total Time for Alertgroup Testing = $elapsed");
}

sub get_alertgroup_cursor {
    my $query   = { parsed => 1 };
    my $sort    = { id  => -1 };
    my $limit   = $LIMIT;
    my $cur     = $prodmongo->collection('Alertgroup')->find($query);
    $cur->sort($sort);
    $cur->limit($limit);
    return $cur;
}

sub test_alertgroup {
    my $ag      = shift;
    my $id      = $ag->id;

    my $timer   = $io->get_timer("AG $id Timer");
    my $updates = $engine->flair_alertgroup($ag);
    my $c_elapsed = &$timer;
    $log->info("======== core ALERTGROUP ".$ag->id.":: $c_elapsed secs =============");
    # say "TIMER [Alertgroup:$id] [core] $elapsed";

    $timer   = $io->get_timer("AG $id Timer");
    my $udefup  = $udengine->flair_alertgroup($ag);
    my $u_elapsed = &$timer;
    $log->info("======== udef ALERTGROUP ".$ag->id.":: $u_elapsed secs =============");
    # say "TIMER [Alertgroup:$id] [udef] $elapsed";

    my $gotedb      = merge_edbs($updates, $udefup);
    my $expected    = get_existing_edb('Alertgroup', $id);
    my $total       = $c_elapsed + $u_elapsed;

    $log->trace({filter=>\&Dumper, value => $gotedb});
    my $result  = compare_edb('Alertgroup', $id, $gotedb, $expected);
    my $msg     = "Alertgroup $id OK [core: $c_elapsed] [udef: $u_elapsed] [total: $total]";
    if ( $result > 1 ) {
        $msg .= "{".($result - 1) . " extra}";
    }
    ok($result, $msg) || bail();
    $RESULTS{'Alertgroup'}{$id} = {
        core    => $c_elapsed,
        udef    => $u_elapsed,
        total   => $total,
        extras  => $result-1,
    };
    $RESULTS{'Alertgroup'}{totals}{count}++;
    $RESULTS{'Alertgroup'}{totals}{core} += $c_elapsed;
    $RESULTS{'Alertgroup'}{totals}{udef} += $u_elapsed;
    $RESULTS{'Alertgroup'}{totals}{total} += $total;
    $RESULTS{'Alertgroup'}{totals}{extras} += $result-1;
}

sub bail {
    return;
    done_testing();
    exit 1;
}

sub test_entry {
    my $e   = shift;
    my $id  = $e->id;

    my $timer   = $io->get_timer("entry total time");
    my $updates = $engine->flair_entry($e);
    my $c_elapsed = &$timer;
    $log->info("======== core ENTRY ".$e->id.":: $c_elapsed secs =============");

    $timer      = $io->get_timer("entry total time");
    my $udefup  = $udengine->flair_entry($e);
    my $u_elapsed    = &$timer;
    $log->info("======== udef ENTRY ".$e->id.":: $u_elapsed secs =============");

    my $gotedb      = merge_edbs($updates, $udefup);
    $log->trace("Got EDB: ",{filter=>\&Dumper, value => $gotedb});
    my $expected    = get_existing_edb('Entry', $id);
    my $total       = $c_elapsed + $u_elapsed;

    my $result  = compare_edb('Entry', $id, $gotedb, $expected);
    my $msg     = "Entry $id OK [core: $c_elapsed] [udef: $u_elapsed] [total: $total] ";
    if ($result > 1 ) {
        $msg .= "{". ($result -1). " extra}";
    }
    ok($result, $msg) || bail();
    $RESULTS{'Entry'}{$id} = {
        core    => $c_elapsed,
        udef    => $u_elapsed,
        total   => $total,
        extras  => $result-1,
    };
    $RESULTS{'Entry'}{totals}{count}++;
    $RESULTS{'Entry'}{totals}{core} += $c_elapsed;
    $RESULTS{'Entry'}{totals}{udef} += $u_elapsed;
    $RESULTS{'Entry'}{totals}{total} += $total;
    $RESULTS{'Entry'}{totals}{extras} += $result-1;
}


sub merge_edbs {
    my $core = shift;
    my $udef = shift;
    my $edb  = {};

    $log->trace("core = ", {filter => \&Dumper, value => $core});

    my $ce = (defined $core->{agupdate}->{entities}) ?
                $core->{agupdate}->{entities} :
                $core->{edb}->{entities};

    $log->trace("udef = ", {filter => \&Dumper, value => $udef->{edb}});

    my $ue = (defined $udef->{agupdate}->{entities}) ?
                $udef->{agupdate}->{entities} :
                $udef->{edb}->{entities};


    foreach my $type (keys %{ $ce }) {
        foreach my $value (keys %{ $ce->{$type} }) {
            $edb->{$type}->{$value}++;
        }
    }
    foreach my $type (keys %{ $ue }) {
        foreach my $value (keys %{ $ue->{$type} }) {
            $edb->{$type}->{$value}++;
        }
    }
    return $edb;
}

sub get_existing_edb {
    my $coln = shift;
    my $id  = shift;
    my $req = {
        collection  => $coln,
        id          => $id,
        subthing    => 'entity',
    };
    my $col = $prodmongo->collection($coln);
    my $cur = $col->api_subthing($req);

    my $edb = {};
    while (my $entity = $cur->next) {
        my $type    = $entity->type;
        my $value   = $entity->value;
        $edb->{$type}->{$value}++;
    }

    $log->trace("Expecting: ",{filter=>\&Dumper, value => $edb});
    return $edb;
}

sub compare_edb {
    my $colname = shift;
    my $id      = shift;
    my $got     = shift;
    my $exp     = shift;
    my %match   = ();

    my $diff    = 0;
    my $xtra    = 0;
    foreach my $type (sort keys %$exp) {

        # ok(defined $got->{$type}, "$colname:$id => $type exists in both");

        foreach my $value (sort keys %{$exp->{$type}}) {

            if ( defined $got->{$type}->{$value} ) {
                # ok(1, "$colname:$id => $type:$value exists in both");
                $match{$type}{both}{$value}++;
                delete $got->{$type}->{$value};
            }
            else {
                # ok(undef, "$colname:$id => $type:$value not found in new flair");
                $match{$type}{old}{$value}++;
                $diff++;
                $RESULTS{missing}{$colname}{$id}{$type}{$value}++;
            }
        }

        if ( keys %{$got->{$type}} ) {
            foreach my $v (sort keys %{$got->{$type}}) {
                # say "$type Entity $v is a new entity found by new flair";
                $match{$type}{new}{$v}++;
                # $diff++;
                $xtra++;
                $RESULTS{extras}{$colname}{$id}{$type}{$v}++;
            }
        }
    }
    if ($diff > 0) {
        print_edb_diff($colname, $id, \%match);
        return 0;
    }
    if ($xtra > 0) {
        return $xtra++; # ensure 2 or higher
    }
    return 1;
}

sub print_edb_diff {
    my $colname = shift;
    my $id      = shift;
    my $match   = shift;

    say "------------------ $colname $id --------------";

    TYPE:
    foreach my $t (sort keys %$match) {
        printf "%25s : %4d matching entities\n", $t, scalar(keys %{$match->{$t}{both}});
        my @n = sort keys %{ $match->{$t}{new} };
        my @o = sort keys %{ $match->{$t}{old} };

        next TYPE if (scalar(@n) == 0 and scalar(@o) == 0);

        printf "%30s %30s\n", "New", "Old";
        my $moredata = 1;

        while ( $moredata ) {
            my $ne = shift @n;
            my $oe = shift @o;

            $ne = '.' if ! defined $ne;
            $oe = '.' if ! defined $oe;

            printf "%30s %30s\n", $ne, $oe; 

            if ( $ne eq '.' and $oe eq '.' ) {
                $moredata = undef;
            }
        }
    }
}


sub compare_entries {
    my $timer   = $io->get_timer('entries total time');
    my $cursor  = get_entry_cursor();

    while ( my $e = $cursor->next) {
        $log->trace("entry body = ".$e->body);
        test_entry($e);
    }
    my $elapsed = &$timer;
    $log->info("++++ Total Time for Entry Testing = $elapsed");
}

sub get_entry_cursor {
    my $query   = {};
    my $sort    = { id => -1};
    my $limit   = $LIMIT;
    my $cur     = $prodmongo->collection('Entry')->find($query);
    $cur->sort($sort);
    $cur->limit($limit);
    return $cur;
}


