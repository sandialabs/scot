#!/usr/bin/env perl
use lib '../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use DateTime;
use DateTime::Duration;

my $t   = Test::Mojo->new('Scot');

my $defgroups   = [ qw(ir test) ];
my $discovery_dt    = DateTime->now();
my $report_delta    = DateTime::Duration->new(hours => 2);
my $report_dt       = $discovery_dt + $report_delta;
my $report_delta2    = DateTime::Duration->new(minutes => 2);
my $report_dt2       = $discovery_dt + $report_delta2;

$t  ->get_ok('/scot/incident')
    ->status_is(200)
    ->json_has('/status' => "no matching permitted records");

$t  ->post_ok('/scot/incident' => json => {
        subject         => "Incident Test 1",
        type            => "Type 1: Information Compromise",
        category        => "IMI-2",
        sensitivity     => "PII",
        security_category   => "low",
        readgroups      => $defgroups,
        modifygroups    => $defgroups,
        discovered      => $discovery_dt->epoch(),
        reported        => $report_dt->epoch(),
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $incident_1  = $t->tx->res->json->{id};

$t  ->post_ok('/scot/incident' => json => {
        subject     => "Incident Test 2",
        type            => "Type 1: Information Compromise",
        category        => "IMI-3",
        sensitivity     => "OUO",
        security_category   => "low",
        readgroups      => $defgroups,
        modifygroups    => $defgroups,
        discovered      => $discovery_dt->epoch(),
        reported        => $report_dt2->epoch(),
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $incident_2  = $t->tx->res->json->{id};

my $json    = Mojo::JSON->new;
my $cols    = $json->encode([qw(incident_id category occurred discovered updated reporting_deadline)]);
my $filter  = $json->encode({incident_id => [ $incident_1, $incident_2 ]});
my $grid    = $json->encode({sort_ref => { incident_id => -1 }});
my $url =   "/scot/incident?columns=$cols&filters=$filter&grid=$grid";

$t  ->get_ok($url, "Get Incident List" )
    ->status_is(200)
    ->json_is('/data/0/incident_id' => $incident_2)
    ->json_is('/data/0/reporting_deadline' => "met")
    ->json_is('/data/1/incident_id' => $incident_1)
    ->json_is('/data/1/reporting_deadline' => "missed");

my $ots1    = $t->tx->res->json->{data}->[0]->{occurred};
my $dis1    = $t->tx->res->json->{data}->[0]->{discovered};
my $upd1    = $t->tx->res->json->{data}->[0]->{updated};

sleep 1;

my $tx  = $t->ua->build_tx(
        PUT => "/scot/incident/$incident_1" => json => {
            subject             => "updated desc",
            security_category   => "high",
            category            => "IMI-2",
        });
$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t->get_ok("/scot/incident/$incident_1")
  ->status_is(200)
  ->json_is('/data/subject'             => "updated desc")
  ->json_is('/data/security_category'   => 'high')
  ->json_is('/data/category'            => 'IMI-2');

isnt $t->tx->res->json->{updated}, $upd1, "update time changed";


$t->delete_ok("/scot/incident/$incident_2" => {} => "Incident Deletion")
  ->status_is(200)
  ->json_is('/status' => 'ok');

# XXX
#  print Dumper($t->tx->res->json);
#  done_testing();
#  exit 0;

$t  ->post_ok('/scot/entry'    => json => {
        body        => "The 6th sense",
        target_id   => $incident_1,
        target_type => "incident",
        parent      => 0,
        readgroups  => [qw(ir test)],
        modifygroups => [qw(ir test)],
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/incident/$incident_1")
    ->status_is(200)
    ->json_is('/data/entries/0/body_plaintext' => "The 6th sense");

done_testing();
exit 0;

