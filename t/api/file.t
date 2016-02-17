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
        subject => "File Test Event 1",
        source  => ["fu"],
        status  => 'open',
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_id = $t->tx->res->json->{id};

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

$t  ->post_ok('/scot/file'  => form => {
    upload      => { file => "./test_file" },
    target_type => "event",
    target_id   => $event_id,
    entry_id    => $entry1,
})->status_is(200);


 print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



