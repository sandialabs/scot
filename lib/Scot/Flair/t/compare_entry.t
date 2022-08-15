#!/usr/bin/env perl

use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use MongoDB::Database;
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

while ( $count++ < $limit ) {

    my $rando = int(rand($total_entries))+1;
    my $prod_entry_href = $prod_entry_col->find_one({id => $rando});
    if (! defined $prod_entry_href) {
        say "NULL ENTRY $rando";
        $count--;
        next;
    }
    say "---- Entry $rando -----";

    my $prod_body   = $prod_entry_href->{body};
    my $prod_flair  = $prod_entry_href->{body_flair};
    my $prod_plain  = $prod_entry_href->{body_plain};
    my $target      = $prod_entry_href->{target};

    unless (create_target($target)){
        say "can't create target ".Dumper($target);
        $count--;
        next;
    }

    my $entry = $col->exact_create($prod_entry_href);
    my $flair_time = $env->get_timer("flair ".$entry->id);
    my $results = $proc->flair_object($entry);
    my $elapsed = &$flair_time;
    $total_flair_time += $elapsed;
    say "---- Entry $rando : $elapsed -----";

    # is ($results->{flair}, $prod_flair, "flair matches on ".$entry->id);

    my $expected_entities = build_expected_entities($prod_entry_href->{id});
    my $expected_bag = bag($expected_entities);
    ok(compare_edb($results->{entities}, $expected_entities, "EDB Matches entry ".$entry->id) or mydie($results->{entities}, $expected_entities));

}

say "Total Flair Time = ".$total_flair_time;
my $avg = $total_flair_time / $count;
say "Avg   Flair Time = ".$avg;

say "All Test ran in ".&$total_timer;

sub mydie {
    my $g   = shift;
    my $e   = shift;

    print "Test failed:\n";
    print "Got: ".Dumper($g);
    print "\nExp: ".Dumper($e);
    die;
}


sub compare_edb {
    my $g   = shift;
    my $e   = shift;

    foreach my $type (keys %$e) {
        foreach my $value (keys %{$e->{$type}}) {
            if ( ! defined $g->{$type}->{$value} ) {
                print "Expected $type $value but it missing.\n";
                return undef;
            }
        }
    }
    return 1;
}

sub build_expected_entities {
    my $id  = shift;
    my $req = {
        collection  => 'entry',
        id          => $id,
        subthing    => 'entity',
    };

    my $cursor = $mongo->collection('Entry')->api_subthing($req);

    my %e = ();

    while (my $entity = $cursor->next) {
        my $href    = $entity->as_hash;
        my $type    = $entity->type;
        my $value   = $entity->value;
        print "Entity = ".Dumper($href);
        if ( defined $type and defined $value ) {
            $e{$type}{$value}++;
        }
    }
    return \%e;
}

sub create_target {
    my $target  = shift;
    my $type    = $target->{type};
    my $id      = $target->{id};
    if ( ! defined $id or $id == 0 ) {
        return undef;
    }
    my $prod_target_col = $proddb->get_collection($type);
    my $prod_href       = $prod_target_col->find_one({id => $id});
    my $target_object   = $mongo->collection(ucfirst($type))->exact_create($prod_href);
    if ( defined $target_object ) {
        return 1;
    }
    return undef;
}
    









done_testing();
