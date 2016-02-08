#!/usr/bin/env perl

use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Mojo::JSON qw(decode_json encode_json);

$ENV{'scot_mode'}   = "testing";
print "Resetting test db...\n";
system("mongo scot-testing <../../bin/database/reset.js 2>&1 > /dev/null");
my @defgroups       = ( 'ir', 'testing' );

my $t   = Test::Mojo->new('Scot');

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 1",
        source  => "firetest",
        status  => 'open',
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_id = $t->tx->res->json->{id};

$t  ->post_ok('/scot/api/v2/incident' => json => {
        events  => [ $event_id ],
        reportable  => 1,
        status      => 'open',
        category    => 'IMI-1',
        sensitivity => 'very',
        occurred    => 1444309925,
        discovered    => 1444319925,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $incident1 = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/incident/$incident1")
    ->status_is(200)
    ->json_is('/reportable' => 1)
    ->json_is('/deadline_status'    => 'future')
    ->json_is('/occurred'   => 1444309925)
    ->json_is('/events/0'   => $event_id);



#  print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



