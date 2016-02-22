#!/usr/bin/env perl

use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Mojo::JSON qw(decode_json encode_json);

print "Resetting test db...\n";
system("mongo scot-testing <../../bin/database/reset.js 2>&1 > /dev/null");

$ENV{'scot_mode'}   = "testing";
my @defgroups       = ( 'ir', 'testing' );

my $t   = Test::Mojo->new('Scot');

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Entry Test Event 1",
        source  => "threadtest",
        status  => 'open',
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_id = $t->tx->res->json->{id};

$t  ->post_ok('/scot/api/v2/entry' => json => {
        body        => "Entry 1 on Event $event_id",
        target_id   => $event_id,
        target_type => "event",
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry1 = $t->tx->res->json->{id};

$t  ->post_ok('/scot/api/v2/entry'  => json => {
        body        => "Entry 1.a on event $event_id",
        target_id   => $event_id,
        target_type => "event",
        parent     => $entry1,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry1a = $t->tx->res->json->{id};

$t  ->post_ok('/scot/api/v2/entry'  => json => {
        body        => "Entry 1.a.i on event $event_id",
        target_id   => $event_id,
        target_type => "event",
        parent     => $entry1a,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry1ai = $t->tx->res->json->{id};

$t  ->post_ok('/scot/api/v2/entry'  => json => {
        body        => "Entry 1.b on event $event_id",
        target_id   => $event_id,
        target_type => "event",
        parent     => $entry1,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry1b = $t->tx->res->json->{id};

$t  ->post_ok('/scot/api/v2/entry'    => json => {
        body        => "Entry 2 on event $event_id",
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry2  = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/event/$event_id/entry")
    ->status_is(200)
    ->json_is('/totalRecordCount' => 2)
    ->json_is('/records/0/id'   => $entry1)
    ->json_is('/records/0/children/0/id'    => $entry1a)
    ->json_is('/records/0/children/0/children/0/id'    => $entry1ai)
    ->json_is('/records/0/children/1/id'    => $entry1b)
    ->json_is('/records/1/id'   => $entry2);

  print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



