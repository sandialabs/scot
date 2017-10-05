#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';

use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Mojo::JSON qw(decode_json encode_json);

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.test.log";
$ENV{'scot_config_paths'}   = '../../../Scot-Internal-Modules/etc';
$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';

print "Resetting test db...\n";
system("mongo scot-testing <../../install/src/mongodb/reset.js 2>&1 > /dev/null");

my @defgroups       = ( 'wg-scot-ir', 'testing' );

my $t   = Test::Mojo->new('Scot');

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Entry Test Event 1",
        source  => ["threadtest"],
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

$t  ->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200)
    ->json_is('/entry_count'    => 1 );


$t  ->post_ok('/scot/api/v2/entry'  => json => {
        body        => "Entry 1.a on event $event_id",
        target_id   => $event_id,
        target_type => "event",
        parent     => $entry1,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry1a = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200)
    ->json_is('/entry_count'    => 2 );


$t  ->post_ok('/scot/api/v2/entry'  => json => {
        body        => "Entry 1.a.i on event $event_id",
        target_id   => $event_id,
        target_type => "event",
        parent     => $entry1a,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry1ai = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200)
    ->json_is('/entry_count'    => 3 );

$t  ->post_ok('/scot/api/v2/entry'  => json => {
        body        => "Entry 1.b on event $event_id",
        target_id   => $event_id,
        target_type => "event",
        parent     => $entry1,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry1b = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200)
    ->json_is('/entry_count'    => 4 );


$t  ->post_ok('/scot/api/v2/entry'    => json => {
        body        => "Entry 2 on event $event_id",
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry2  = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200)
    ->json_is('/entry_count'    => 5 );


$t  ->get_ok("/scot/api/v2/event/$event_id/entry")
    ->status_is(200)
    ->json_is('/totalRecordCount' => 2)
    ->json_is('/records/0/id'   => $entry1)
    ->json_is('/records/0/children/0/id'    => $entry1a)
    ->json_is('/records/0/children/0/children/0/id'    => $entry1ai)
    ->json_is('/records/0/children/1/id'    => $entry1b)
    ->json_is('/records/1/id'   => $entry2);

$t  ->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200)
    ->json_is('/entry_count'    => 5);

my $pre_delete_updated      = $t->tx->res->json->{updated};
my $pre_delete_entry_count  = $t->tx->res->json->{entry_count};
sleep 1;

print "Pre delete entry count is $pre_delete_entry_count\n";
$t  ->delete_ok("/scot/api/v2/entry/$entry2")
    ->status_is(200);

$t  ->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200)
    ->json_is('/entry_count'    => 4);


$t  ->get_ok("/scot/api/v2/entry/$entry2")
    ->status_is(404);

$t  ->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200)
    ->json_is('/entry_count'    => $pre_delete_entry_count -1 );

my $post_delete_updated = $t->tx->res->json->{update};

ok( $pre_delete_updated != $post_delete_updated, "updated time was updated");

$t  ->put_ok("/scot/api/v2/entry/$entry1" => json => {
    body => "Updated Entry"
})  ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/api/v2/entry/$entry1")
    ->status_is(200)
    ->json_is('/body'   => 'Updated Entry');

 print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



