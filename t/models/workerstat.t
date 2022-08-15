#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '../../lib';

use Test::More;
use Meerkat;
use Data::Dumper;
use Scot::Model::WorkerStat;
use Scot::Env;
use DateTime;
use Log::Log4perl::Level;

BEGIN {
    use_ok("Meerkat");
};

system("mongo scot-dev ./reset_db.js");

my $mongo   =  Meerkat->new(
    model_namespace         => "Scot::Model",
    collection_namespace    => "Scot::Collection",
    database_name           => "scot-dev",
    client_options          => {
        host        => "mongodb://localhost",
        w           => 1,
        find_master => 1,
    },
);

$ENV{scot_config_file} = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';
my $env = Scot::Env->new();
my $log = $env->log;
$log->level($TRACE);
$log->trace("WTF");


ok (defined $mongo, "We have a mongo connection");
is (ref($mongo), "Meerkat", "and it is a Meerkat object");

$log->trace("WTF");
my $dt  = DateTime->now;

my $stat  = $mongo->collection("WorkerStat");
ok (defined $stat, "Collection object is defined");
$log->trace("WTF");

my $rec = {
    processed_count     => 0,
    total_node_count    => 0,
    procid  => 123,
    node    => 0,
    oid     => 321,
    otype   => 'alert'
};

my $stat1    = $stat->create($rec);

ok (defined $stat1, "workerstat 1 created");
is ($stat1->id, 1, "ID is correct");



done_testing();
exit 0;
