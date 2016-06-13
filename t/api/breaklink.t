#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Mojo::JSON qw(decode_json encode_json);

$ENV{'scot_mode'}   = "testing";
$ENV{'SCOT_AUTH_TYPE'}   = "Testing";
$ENV{'scot_env_configfile'} = '../../../Scot-Internal-Modules/etc/scot_env_test.cfg';
print "Resetting test db...\n";
system("mongo scot-testing <../../etc/database/reset.js 2>&1 > /dev/null");

my @defgroups       = ( 'wg-scot-ir', 'testing' );

my $t   = Test::Mojo->new('Scot');

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 1",
        source  => "firetest",
        tag     => [ 'baz', 'bur' ],
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
    ->json_is('/owner'  => 'scot-admin')
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
    ->json_is('/owner'  => 'scot-admin')
    ->json_is('/status'  => 'open')
    ->json_is('/subject'    => 'Test Event 1');

my $tx  = $t->ua->build_tx(
    PUT =>"/scot/api/v2/event/$event_id" => json =>{
    tag  => ["foo","boo", "bur", "baz"],
});


$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'successfully updated');


$t  ->get_ok("/scot/api/v2/tag")
    ->status_is(200)
    ->json_is('/queryRecordCount'   => 4)
    ->json_is('/records/0/value'   => 'boo')
    ->json_is('/records/1/value'   => 'foo')
    ->json_is('/records/2/value'   => 'bur')
    ->json_is('/records/3/value'   => 'baz');


my $foo_tag_id  = $t->tx->res->json->{records}->[1]->{id};

$t->get_ok("/scot/api/v2/event/$event_id/tag")
    ->status_is(200)
    ->json_is('/records/0/value' => "baz")
    ->json_is('/records/1/value' => "bur")
    ->json_is('/records/2/value' => "foo")
    ->json_is('/records/3/value' => "boo");

$t->delete_ok("/scot/api/v2/event/$event_id/tag/$foo_tag_id")
    ->status_is(200);


$t->get_ok("/scot/api/v2/tag") 
    ->status_is(200)
    ->json_is('/queryRecordCount'   => 4)
    ->json_is('/records/0/value'   => 'boo')
    ->json_is('/records/1/value'   => 'foo')
    ->json_is('/records/2/value'   => 'bur')
    ->json_is('/records/3/value'   => 'baz');

$t->get_ok("/scot/api/v2/event/$event_id/tag")
    ->status_is(200)
    ->json_is('/records/0/value' => "baz")
    ->json_is('/records/1/value' => "bur")
    ->json_is('/records/2/value' => "boo");

# print Dumper($t->tx->res->json);
 done_testing();
 exit 0;

 done_testing();
 exit 0;


