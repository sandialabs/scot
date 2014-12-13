use lib '../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;

# system("mongo scotng-test ./reset_entry_db.js");

my $t = Test::Mojo->new('Scot');
my $json    = Mojo::JSON->new;

# JSON 
# get alerts for grid, should be none
$t  ->get_ok('/scot/entry')
    ->status_is(200)
    ->json_has('/status' => "no matching permitted records");

# get an alert to work with
my $cols    = $json->encode([qw(alert_id subject)]);
my $url = "/scot/alert?columns=$cols";
$t  ->get_ok($url, "get alerts" )
    ->status_is(200);

my $alertlist       = $t->tx->res->json;
my $alert_subject   = $alertlist->{data}->[0]->{subject};
my $alert_id        = $alertlist->{data}->[0]->{alert_id};


$t  ->post_ok('/scot/entry' => json => {
        body        => "There comes time in the course of human events...",
        target_id   => $alert_id,
        target_type => "alert",
        readgroups  =>  [qw(ir test)],
        modifygroups => [qw(ir test)],
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry_1 = $t->tx->res->json->{id} + 0;

$t  ->post_ok('/scot/entry' => json => {
        body        => "I do not like green eggs and ham, Sam I am",
        target_id   => $alert_id,
        target_type => "alert",
        parent      => $entry_1,
        readgroups  => [qw(ir test)],
        modifygroups => [qw(ir test)],
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');
my $entry_2 = $t->tx->res->json->{id} + 0;

$t  ->post_ok('/scot/entry' => json => {
        body        => "entry number 3",
        target_id   => $alert_id,
        target_type => "alert",
        parent      => $entry_1,
        readgroups  => [qw(ir test)],
        modifygroups => [qw(ir test)],
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry_3 = $t->tx->res->json->{id} + 0;

$t  ->get_ok("/scot/entry/$entry_3")
    ->status_is(200);

my $entry3update = $t->tx->res->json->{data}->{updated};

sleep 1;


my $tx  = $t->ua->build_tx(
    PUT => "/scot/entry/$entry_3" => 
    json => { body => "updated numero tres entry, 10.1.1.1" }
);

$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');


# my $text_target = qq|updated numero tres entry, <span data-entity-value="10.1.1.1" data-entity-type="ipaddr" class="entity ipaddr">10.1.1.1</span>|;
my $text_target = qq|<html><head></head><body><p>updated numero tres entry, <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.1.1.1">10.1.1.1</span></body></html>|;

$t  ->get_ok("/scot/entry/$entry_3")
    ->status_is(200)
    ->json_is('/data/body_flaired'  => $text_target);


isnt $t->tx->res->json->{data}->{updated}, $entry3update, "update time updated";

my $tx = $t->ua->build_tx(PUT => "/scot/entry/$entry_3" => json => { parent => 0, });

$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/entry/$entry_3")
    ->status_is(200)
    ->json_is('/data/parent'  => 0);

# test if flattening and threading of entries works
# entry_1
#     entry_2
# entry_3

$t  ->get_ok("/scot/alert/$alert_id")
    ->status_is(200)
    ->json_is('/data/entries/0/children/0/entry_id' => $entry_2);

#  print Dumper($t->tx->res->json);
#  exit 0;





$t  ->post_ok(
        '/scot/entry'    => json => {
            body        => "Kyle Macy #4",
            target_id   => $alert_id,
            target_type => "alert",
            parent      => $entry_3,
            readgroups  => [qw(ir test)],
            modifygroups => [qw(ir test)],
        }
    )
    ->status_is(200)
    ->json_is('/status' => 'ok');
my $entry_4 = $t->tx->res->json->{id} + 0;
# entry_1
#     entry_2
# entry_3
#     entry_4


$t  ->get_ok("/scot/alert/$alert_id")
    ->status_is(200)
    ->json_is('/data/entries/1/children/0/entry_id' => $entry_4);

# exit 0;

$t  ->delete_ok("/scot/entry/$entry_4" => {} => 'Entry Deletion')
    ->status_is(200)
    ->json_is('/status' => 'ok');
# XXX
# print Dumper($t->tx->res->json);
# done_testing();
# exit 0;



$t  ->post_ok(
    '/scot/entry'    => json => {
        body        => "Kyle Macy #4",
        target_id   => $alert_id,
        target_type => "alert",
        parent      => $entry_3,
        readgroups  => [qw(ir test)],
        modifygroups => [qw(ir test)],
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');
$entry_4 = $t->tx->res->json->{id} + 0;

my $json    = Mojo::JSON->new;
my $filter  = $json->encode({ entry_id => [ $entry_1, $entry_2, $entry_3, $entry_4 ]});
my $cols    = $json->encode([qw(entry_id parent target_type target_id when)]);
my $url     = "/scot/entry?columns=$cols&filters=$filter";

$t  ->get_ok($url, "get entry list" )
    ->status_is(200)
    ->json_has('/status' => "ok");
#    ->json_is('/data/0/entry_id'    => $entry_3)
#    ->json_is('/data/1/entry_id'    => $entry_4)
#    ->json_is('/data/2/entry_id'    => $entry_1)
#    ->json_is('/data/3/entry_id'    => $entry_2);
# print Dumper($t->tx->res->json->{data});


$t  ->post_ok('/scot/entry'    => json => {
        body        => "I love Testing!!!!",
        target_id   => $alert_id,
        target_type => "alert",
        parent      => $entry_1,
        readgroups  => [qw(ir test)],
        modifygroups => [qw(ir test)],
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');
my $entry_5  = $t->tx->res->json->{id} + 0;

$t  ->post_ok('/scot/entry'    => json => {
        body        => "Yeah Testing!!!!",
        target_id   => $alert_id,
        target_type => "alert",
        parent      => $entry_5,
        readgroups  => [qw(ir test)],
        modifygroups => [qw(ir test)],
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');
my $entry_6  = $t->tx->res->json->{id} + 0;
print "Last Entry is $entry_6\n";

# entry_1
#     entry_2
#     entry_5
#       entry_6
# entry_3
#     entry_4

$t  ->post_ok('/scot/event' => json => {
    subject     => "Test target for moving entry",
    source      => 'todd',
    readgroups  => [ qw(test ir) ],
    modifygroups=> [ qw(test ir) ],
})->status_is(200)
    ->json_is('/status' => 'ok');
my $event_id = $t->tx->res->json->{id};

my $tx = $t->ua->build_tx(PUT => "/scot/entry/$entry_5" => json => {
    target_id       => $event_id,
    target_type     => "event",
});

$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/entry/$entry_5")
    ->status_is(200)
    ->json_is('/data/target_id'  => $event_id)
    ->json_is('/data/target_type'  => "event");

$t  ->get_ok("/scot/event/$event_id")
    ->status_is(200);


  # print Dumper($t->tx->res->json);

done_testing();
exit 0;
