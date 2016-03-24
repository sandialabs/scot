#!/usr/bin/env perl
use lib '../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;

my $t   = Test::Mojo->new('Scot');

$t  ->post_ok( '/scot/alert'    => json => {
                    source      => "tests",
                    subject     => "future promoted alert",
                    data        => {
                        text    => "this alert will go places, mark my words",
                    },
                    readgroups  => [ qw(ir test) ],
                    modifygroups => [ qw(ir test) ],
                }
            )
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $alert_id    = $t->tx->res->json->{id};

my $tx  = $t->ua->build_tx(
    PUT => "/scot/promote"  => json => {
        thing   => "alert",
        id      => $alert_id,
    });

$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok')
    ->json_is('/thing'  => "event");

my $event_id    = $t->tx->res->json->{id};

$tx = $t->ua->build_tx(
    PUT => "/scot/promote" => json => {
        thing   => "event",
        id      => $event_id,
    });

$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok')
    ->json_is('/thing'  => "incident");

my $incident_id = $t->tx->res->json->{id};

done_testing();
exit 0;
