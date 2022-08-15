#!/usr/bin/env perl

use strict;
use warnings;
use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use MongoDB::Database;
use HTML::Entities;
use IO::Handle;
use feature qw(say);

my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new({config_file => $config_file});
ok(defined $env, "Environment defined");
is(ref($env), "Scot::Env", "it is a Scot::Env");

require_ok('Scot::Flair::Worker');
my $worker = Scot::Flair::Worker->new({env => $env});
ok(defined $worker, "Worker module instantiated");
ok(ref($worker) eq 'Scot::Flair::Worker', 'got what we expected');

my $proc = $worker->get_processor({data => { type => 'entry' }});
my $extractor   = $worker->extractor;

my $proddb  = MongoDB->connect->db('scot-prod');
my $prod_entry_col = $proddb->get_collection('entry');

my $mongo   = $env->mongo;
my $col     = $mongo->collection('Entry');

my $total_timer = $env->get_timer("total_timer");

my $count   = 0;
my $limit   = 1000;
my $prob    = .01;
my $total_entries = $prod_entry_col->count_documents({});
my $total_flair_time = 0;

open my $fh, '>>', "stats.csv" or die "Can't open stats.csv: $!";
$fh->autoflush(1);
my $header = join(',', 'id', 'chars', 'entities', 'recurse', 'time')."\n";
print $fh $header;

while ( $count++ < $limit ) {

    my $rando = int(rand($total_entries))+1;
    my $prod_entry_href = $prod_entry_col->find_one({id => $rando});
    if (! defined $prod_entry_href) {
        say "NULL ENTRY $rando";
        $count--;
        next;
    }
    say "---- Entry $rando -----";

    my $source          = $prod_entry_href->{body};
    my $len             = length($source);
    say "    length         = $len";
    # my $expected_flair  = decode_entities($prod_entry_href->{body_flair});
    my $expected_edb    = build_expected_edb($rando);
    if ( $len > 1000000 ) {
        print "Larger than 1M chars, only doing core regexes\n";
        $expected_edb->{core}++;
    }

    my $gotedb  = {};
    my $flair_time = $env->get_timer("flair ".$rando);
    my @got     = $extractor->parse("Entry $rando", $gotedb, $source);
    my $elapsed = &$flair_time;
    my $entities_found = keys %{$gotedb->{entities}};
    my $ml = $extractor->max_level;
    say "    Flair time     = $elapsed";
    say "    Entities Found = $entities_found";
    say "    recurse level  = $ml";
    if ( $entities_found > 0 ) {
        say "    Time/Entity    = ".$elapsed/$entities_found;
    }
    $extractor->max_level(0);
    my $line = join(',',$rando,$len,$entities_found, $ml, $elapsed)."\n";
    print $fh $line;

    $total_flair_time += $elapsed;

    ok(compare_edb($gotedb->{entities}, $expected_edb), "Entry $rando EDB is correct") || die;
    # ok(compare_flair(\@got, $expected_flair), "Entry $rando Flair matches");
}

close $fh;

say "Total Flair Time   = $total_flair_time";
my $avg = $total_flair_time / $count;
say "Avg Flair/Entry    = $avg";
say "All Tests elapsed  = ".&$total_timer;

sub compare_edb {
    my $g   = shift;
    my $e   = shift;

    foreach my $type (keys %$e) {
        foreach my $value (keys %{$e->{$type}}) {
            if ( ! defined $g->{$type}->{$value} ) {
                print "Missing $type $value in parsed edb\n";
                print "Got: ".Dumper($g);
                print "Exp: ".Dumper($e);
                return undef;
            }
        }
    }
    return 1;
}

sub compare_flair {
    my $g   = shift;
    my $e   = shift;

    my $gflair  = "<div>".$extractor->build_html(@$g)." </div>";

    if ( $gflair ne $e ) {
        print "Flair Differs!\n";
        print "Got: $gflair\n";
        print "Exp: $e\n";
        show_diff($gflair,$e);
        return undef;
    }
    return 1;
}

sub show_diff {
    my $g   = shift;
    my $e   = shift;

    my @gwords  = split(/\s+/, $g);
    my @ewords  = split(/\s+/, $e);

    for (my $i = 0; $i < scalar(@gwords); $i++ ) {
        if ( $gwords[$i] ne $ewords[$i] ) {
            print "Word $i differs:\n";
            print "Got: $gwords[$i]\n";
            print "Exp: $ewords[$i]\n";
            return;
        }
    }
}

sub build_expected_edb {
    my $id      = shift;
    my $vertex  = {
        id      => $id,
        type    => 'entry'
    };
    my $query   = {
        '$and'  => [
            { vertices => { '$elemMatch' => $vertex } },
            { 'vertices.type' => 'entity' },
        ],
    };
    my $cursor  = $proddb->get_collection('Link')->find($query);

    my %edb = ();

    while ( my $href = $cursor->next ) {

        my $value   = $href->{value};
        my $type    = $href->{type};

        $edb{$type}{$value} ++;
    }
    return \%edb;
}

