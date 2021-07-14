#!/usr/bin/env perl

use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use MongoDB::Database;
use feature qw(say);

my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new({config_file=>$config_file});
ok(defined $env, "Environment defined");
is(ref($env), "Scot::Env", "and its a Scot::Env");

require_ok('Scot::Flair::Worker');
my $worker = Scot::Flair::Worker->new({env => $env});
ok(defined $worker, "worker instantiated");
ok(ref($worker) eq "Scot::Flair::Worker", "its a Scot::Flair::Worker");

my $proc    = $worker->get_processor({data => { type => 'alertgroup' } });
my $proddb  = MongoDB->connect->db('scot-prod');
my $p_a_col= $proddb->get_collection('alert');
my $mongo   = $env->mongo;
my $acol    = $mongo->collection('Alert');

my $total_time = $env->get_timer("Total_Time");

my $do_this_id = $ARGV[0] + 0;

my $count   = 0;
my $limit   = 100;
my $prob    = 0.01;
my $total_a = $p_a_col->count_documents({});
my $total_flair_time = 0;

say "Total alerts = $total_a";

while ( $count++ < $limit ) {

    my $rando       = int(rand($total_a)) + 1;

    if ( $do_this_id > 0 ) {
        $rando = $do_this_id;
    }
    my $p_a_href    = $p_a_col->find_one({id => $rando});

    if ( ! defined $p_a_href ) {
        say "NULL Alert found: $rando";
        $count--;
        next;
    }

    say "Alert $rando ----------------";

    my $p_data          = $p_a_href->{data};

    foreach my $key (keys %$p_data) {
        next if $key eq "columns" or $key eq "_raw";

        my $plain_aref  = $p_data->{$key};
        my $exp_edb     = build_expected_edb($rando);

        my @got = $extractor->parse();
    }
}
