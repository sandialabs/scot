#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Collection;
use Scot::Collection::Alertgroup;

$ENV{'scot_mode'}   = "testing";
system("mongo scot-testing ../../bin/reset_db.js");

@defgroups = ( 'ir', 'test' );

my $t = Test::Mojo->new('Scot');

$t->post_ok(
    '/scot/api/v2/alertgroup'   => json => {
        message_id  => '112233445566778899aabbccddeeff',
        subject     => 'test message 1',
        data        => [
            {  foo   => 1,   bar => 2 },
            {  foo   => 3,   bar => 4 },
        ],
        tags     => [qw(test testing)],
        sources  => [qw(todd scot)],
        columns  => [qw(foo bar) ],
    }
)->status_is(200);

my $alertgroup_id   = $t->tx->res->json->{id};
my $updated         = $t->tx->res->json->{updated};

$t->post_ok(
    '/scot/api/v2/alertgroup'   => json => {
        message_id  => '112233445566778899aabbccddeeee',
        subject     => 'test message 2',
        data        => [
            {  boom   => 1,   baz => 2 },
            {  boom   => 3,   baz => 4 },
        ],
        tags     => [qw(test testing)],
        sources  => [qw(todd scot)],
        columns  => [qw(foo bar) ],
    }
)->status_is(200);

my $alertgroup_id2   = $t->tx->res->json->{id};

$t->get_ok('/scot/api/v2/supertable' => json => {
    alertgroup => [ $alertgroup_id, $alertgroup_id2 ]
})->status_is(200);

print Dumper($t->tx->res->json), "\n";

$t->get_ok("/scot/api/v2/supertable?alertgroup=$alertgroup_id&alertgroup=$alertgroup_id2")
    ->status_is(200);

done_testing();
exit 0;

