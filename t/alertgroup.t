#!/usr/bin/env perl
use lib '../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;

system("mongo scotng-dev ./reset_alert_db.js");

my $t = Test::Mojo->new('Scot');

# JSON 
# get alerts for grid
# add and alert
$t  ->post_ok(
        '/scot/alert' => json => {
            sources      => ["tests"],
            subject     => "Test Alertgroup alert one",
            alertgroup  => 123,
            tags        => [qw(foo test)],
            data        => {
                    text    => "This is a test of the alert creation",
            },
            readgroups      => [ qw(ir test) ],
            modifygroups    => [ qw(ir test) ],
        }
    )
    ->status_is(200)
    ->json_is('/status' => 'ok');
my $alert1 = $t->tx->res->json->{id};



$t  ->post_ok('/scot/alert' => json => {
       sources      => ["tests"],
       subject      => "Test Alertgroup alert one",
       alertgroup   => 123,
       tags         => [qw(bar baz) ],
       data         => {
            text    => "Flairable stuff follows: newcmd.exe was downloaded from haxor.edu"
       },
       readgroups   => [ qw(ir test) ],
       modifygroups => [ qw(ir test) ],
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $alert2 = $t->tx->res->json->{id};

$t  ->get_ok("/scot/alertgroup/123" => {
    }, "Get Alertref List" )
    ->status_is(200)
    ->json_is('/data/alerts/0/alert_id'     => $alert1)
    ->json_is('/data/alerts/1/alert_id'     => $alert2)
    ->json_is('/data/alerts/0/status'       => 'open')
    ->json_is('/data/alerts/1/status'       => 'open');

$t  ->get_ok("/scot/alertgroup/refresh/123")
    ->status_is(200)
    ->json_is('/data/alertgroup_id'  => "123")
    ->json_is('/data/tags'  => [qw(bar baz foo test)])
    ->json_is('/data/status'    => "open");


$t  ->get_ok("/scot/alertgroup"    => {}, "Get Alergroup Grid" )
    ->status_is(200);

# test updates to an alert
my $tx = $t->ua->build_tx(
    PUT => "/scot/alert/$alert1" => json => {
        status  => "closed",
    }
);
$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/alertgroup/refresh/123")
    ->status_is(200)
    ->json_is('/data/alertgroup_id'  => "123")
    ->json_is('/data/tags'  => [qw(bar baz foo test)])
    ->json_is('/data/status'    => "open");


$t  ->post_ok('/scot/alert' => json => {
        sources     => ["tests"],
        subject     => "Test alert 2 for alertgroup 123",
        alertgroup  => 123,
        tags        => [ qw(test bar baz) ],
        data        => {
            text    => "more useless data",
        },
        readgroups  => [ qw(ir test) ],
        modifygroups    => [ qw(ir tests) ],
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $alert3 = $t->tx->res->json->{id};

$t  ->get_ok("/scot/alertgroup/123" => {
    }, "Get Alertref List with new alert" )
    ->status_is(200)
    ->json_is('/data/alerts/0/alert_id'     => $alert1)
    ->json_is('/data/alerts/1/alert_id'     => $alert2)
    ->json_is('/data/alerts/2/alert_id'     => $alert3)
    ->json_is('/data/alerts/2/status'       => 'open');


# test updated to an alertgroup
my $tx  = $t->ua->build_tx(
    PUT => "/scot/alertgroup/123" => json => {
        status  => "closed",
        closed  => 1378497385,
    }
);

$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/alertgroup/123" => {
    }, "Get Alertref List with new alert" )
    ->status_is(200)
    ->json_is('/data/alerts/0/status'       => "closed")
    ->json_is('/data/alerts/1/status'       => "closed")
    ->json_is('/data/alerts/2/status'       => 'closed');

#  print Dumper($t->tx->res->json), "\n";
#  done_testing();
#  exit 0;

my $tx  = $t->ua->build_tx(
    PUT => "/scot/alertgroup/123" => json => {
        status  => "promoted",
        closed  => 1378497385,
    }
);

$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');



$t  ->get_ok("/scot/alertgroup/refresh/123")
    ->status_is(200)
    ->json_is('/data/alertgroup_id'  => "123")
    ->json_is('/data/tags'  => [ qw(bar baz foo test)])
    ->json_is('/data/status'    => "promoted");

# test promotion of alertgroup
#$tx     = $t->ua->build_tx(
#    PUT => "/scot/promote"  => json => {
#        thing   => "alertgroup",
#        id      => 123,
#    }
#);

#$t  ->request_ok($tx)
#    ->status_is(200)
#    ->json_is('/status'   => "ok");

# test promotion of alertgroup
#$tx     = $t->ua->build_tx(
#    PUT => "/scot/promote"  => json => {
#        thing       => "alertgroup",
#        id          => 123,
#        target_id   => 77777,
#    }
#);

#$t  ->request_ok($tx)
#    ->status_is(200)
#    ->json_is('/status'   => "fail");

# test insert of an alertgroup
$t  ->post_ok(
        '/scot/alertgroup' => json => {
            sources      => ["tep"],
            subject     => "Test Alertgroup Creation ",
            tags        => [qw(foo test)],
            data        => [
                    { text  => "This is alert 1" , value => 1,},
                    { text  => "This is alert 2" , value => 2,},
            ],
            columns         => [ qw(value text) ],
            readgroups      => [ qw(ir test) ],
            modifygroups    => [ qw(ir test) ],
        }
    )
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $agid = $t->tx->res->json->{id};

$t  ->get_ok("/scot/alertgroup/$agid" => {
    }, "Get Alertgroup after creation" )
    ->status_is(200)
    ->json_is('/data/alerts/0/data/value'   => 1)
    ->json_is('/data/alerts/1/data/value'   => 2);
    

print Dumper($t->tx->res->json), "\n";
done_testing();
exit 0;

# more tests needed include:
# creation of an alertgroup with all alerts closed and see if status is right
