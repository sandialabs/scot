#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Mojo::JSON qw(decode_json encode_json);

$ENV{'scot_mode'}   = "testing";
my @defgroups       = ( 'ir', 'testing' );

my $t   = Test::Mojo->new('Scot');

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 1",
        source  => "firetest",
        status  => 'open',
#        readgroups  => $defgroups,
#        modifygroups=> $defgroups,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_id = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200)
    ->json_is('/id'     => $event_id)
    ->json_is('/owner'  => 'scot-adm')
    ->json_is('/status'  => 'open')
    ->json_is('/subject' => 'Test Event 1');




$t  ->post_ok('/scot/api/v2/entry' => json => {
        body        => "Entry 1 on Event $event_id",
        target_id   => $event_id,
        target_type => "event",
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry1 = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200)
    ->json_is('/id' => $event_id)
    ->json_is('/owner'  => 'scot-adm')
    ->json_is('/status'  => 'open')
    ->json_is('/subject'    => 'Test Event 1');


$t  ->post_ok  ('/scot/api/v2/event'  => json =>{
        subject => "Test Event 2",
        source  => "foobar",
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
        alert_id    => 2,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_2 = $t->tx->res->json->{id};

my $cols    = encode_json([qw(event_id updated created)]);
my $filter  = encode_json({id   => {'$in' => [ $event_id, $event_2 ]}});
my $grid    = encode_json({'id' => -1});
my $url = "/scot/api/v2/event?columns=$cols&match=$filter&sort=$grid";

$t  ->get_ok($url, "Get Event List" )
    ->status_is(200)
    ->json_is('/records/0/id'    => $event_2)
    ->json_is('/records/1/id'    => $event_id);


my $update2time = $t->tx->res->json->{data}->[1]->{updated};

sleep 1;
print "waking from sleep\n";

my $tx  = $t->ua->build_tx(
    PUT => "/scot/api/v2/event/$event_2" => json => {
    owner   => "boombaz",
});
$t  ->request_ok($tx)
    ->status_is(403);

$tx  = $t->ua->build_tx(
    PUT     => "/scot/api/v2/event/$event_2" => json => {
    status  => "closed",
});

$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'successfully updated');

$t  ->get_ok("/scot/api/v2/event/$event_2")
    ->status_is(200)
    ->json_is('/status'    => "closed");

isnt $t->tx->res->json->{updated}, $update2time, "update time change";

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 3",
        source  => "deltest" ,
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
        alert_id    => 2,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');
    
my $event_3 = $t->tx->res->json->{id};

$t  ->delete_ok("/scot/api/v2/event/$event_3")
    ->status_is(200)
    ->json_is('/status' => 'ok');


$t  ->post_ok('/scot/api/v2/entry'    => json => {
        body        => "The fifth symphony",
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups => $defgroups,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry2  = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/event/$event_id/entry")
    ->status_is(200)
    ->json_is('/totalRecordCount' => 2)
    ->json_is('/records/0/id'   => $entry1)
    ->json_is('/records/1/id'   => $entry2);

my $tx  = $t->ua->build_tx(
    PUT =>"/scot/api/v2/event/$event_id" => json =>{
    tags  => ["foo","boo"],
});

$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'successfully updated');


$t->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200)
    ->json_is('/tags/1' => "boo")
    ->json_is('/tags/0' => "foo");

#  print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



