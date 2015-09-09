#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;

$ENV{'scot_mode'}   = "testing";
my @defgroups       = ( 'ir', 'testing' );

my $t   = Test::Mojo->new('Scot');

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 1",
        source  => "firetest",
#        readgroups  => $defgroups,
#        modifygroups=> $defgroups,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_id = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200);


 print Dumper($t->tx->res->json);
 done_testing();
 exit 0;

$t  ->post_ok('/scot/entry' => json => {
        body        => "Entry 1 on Event $event_id",
        target_id   => $event_id,
        target_type => "event",
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');


$t  ->get_ok("/scot/event/$event_id")
    ->status_is(200)
    ->json_is('/data/entries/0/body_plaintext' => "Entry 1 on Event $event_id");

$t  ->post_ok  ('/scot/event'  => json =>{
        subject => "Test Event 2",
        source  => "foobar",
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
        alert_id    => 2,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_2 = $t->tx->res->json->{id};

my $json    = Mojo::JSON->new;
my $cols    = $json->encode([qw(event_id updated created)]);
my $filter  = $json->encode({event_id   => [ $event_id, $event_2 ]});
my $grid    = $json->encode({sort_ref   => { 'event_id' => -1 } });
my $url = "/scot/event?columns=$cols&filters=$filter&grid=$grid";

$t  ->get_ok($url, "Get Event List" )
    ->status_is(200)
    ->json_is('/data/0/event_id'    => $event_2)
    ->json_is('/data/1/event_id'    => $event_id);


my $update2time = $t->tx->res->json->{data}->[1]->{updated};

sleep 1;
print "waking from sleep\n";

my $tx  = $t->ua->build_tx(
    PUT => "/scot/event/$event_2" => json => {
    owner   => "boombaz",
    status  => "closed",
});
$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/event/$event_2")
    ->status_is(200)
    ->json_is('/data/owner'     => "boombaz")
    ->json_is('/data/status'    => "closed");

isnt $t->tx->res->json->{updated}, $update2time, "update time change";

$t  ->post_ok  ('/scot/event'  => json => {
        subject => "Test Event 3",
        source  => "deltest" ,
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
        alert_id    => 2,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');
my $event_3 = $t->tx->res->json->{id};

$t  ->delete_ok("/scot/event/$event_3" => {} => "Event Deletion")
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->post_ok('/scot/entry'    => json => {
        body        => "The fifth symphony",
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups => $defgroups,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/event/$event_id")
    ->status_is(200)
    ->json_is('/data/entries/1/body_plaintext' => "The fifth symphony");
# XXX
# print Dumper($t->tx->res);
# done_testing();
# exit 0;

my $tx  = $t->ua->build_tx(
    PUT =>"/scot/event/$event_id" => json =>{
    cmd   => "addtag",
    tags  => ["foo"],
});

$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');


my $tx  = $t->ua->build_tx(
    PUT => "/scot/event/$event_id" => json =>{
    cmd   => "addtag",
    tags  => ["boo"],
});
$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t->get_ok("/scot/event/$event_id")
    ->status_is(200)
    ->json_is('/data/tags/0' => "boo")
    ->json_is('/data/tags/1' => "foo");

my $tx  = $t->ua->build_tx(
    PUT => "/scot/event/1" => json =>{
    cmd   => "rmtag",
    tags  => ["foo"],
});
$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t->get_ok("/scot/event/$event_id")
    ->status_is(200)
    ->json_is('/data/tags/0' => "boo");

my $json    = Mojo::JSON->new;
my $jfilter = $json->encode({ limit => 100, sort_ref => { subject => 1}});


done_testing();
exit 0;

 print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



