#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Collection;
use Scot::Collection::Alertgroup;

$ENV{'scot_mode'}   = "testing";
print "Resetting test db...\n";
system("mongo scot-testing <../../bin/database/reset.js 2>&1 > /dev/null");

@defgroups = ( 'ir', 'test' );

my $t = Test::Mojo->new('Scot');
my $env = Scot::Env->instance;
#my $amq = $env->amq;
#$amq->subscribe("alert", "alert_queue");
#$amq->get_message(sub{
#    my ($self, $frame) = @_;
#    print "AMQ received: ". Dumper($frame). "\n";
#});


$t->post_ok(
    '/scot/api/v2/alertgroup'   => json => {
        message_id  => '112233445566778899aabbccddeeff',
        subject     => 'test message 1',
        data        => [
            { foo   => 1,   bar => 2 },
            { foo   => 3,   bar => 4 },
        ],
        tags     => [qw(test testing)],
        sources  => [qw(todd scot)],
        columns  => [qw(foo bar) ],
    }
)->status_is(200)
 ->json_is('/id'    => 1);

my $alertgroup_id   = $t->tx->res->json->{id};
my $updated         = $t->tx->res->json->{updated};


$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/alert" => {},
           "Get alertgroup $alertgroup_id" )
    ->status_is(200)
    ->json_is('/totalRecordCount'   => 2)
    ->json_is('/queryRecordCount'   => 2)
    ->json_is('/records/0/alertgroup'   => $alertgroup_id)
    ->json_is('/records/1/alertgroup'   => $alertgroup_id)
    ->json_is('/records/0/data/foo'     => 1)
    ->json_is('/records/1/data/foo'     => 3);

my $alert_1_id  = $t->tx->res->json->{records}->[0]->{id};
my $alert_2_id  = $t->tx->res->json->{records}->[1]->{id};


$t->put_ok("/scot/api/v2/alert/$alert_1_id" => json => 
    {
        promote => "new",
    } 
)->status_is(200)
 ->json_is('/status'    => "successfully promoted");

my $event1  = $t->tx->res->json->{id};

#print Dumper($t->tx->res->json), "\n";
#done_testing();
#exit 0;

$t->get_ok("/scot/api/v2/event/$event1/alert" => {},
    "Get alerts promoted to Event $event1")
    ->status_is(200)
    ->json_is('/records/0/id'           => 1)
    ->json_is('/records/0/status'       => 'promoted')
    ->json_is('/records/0/alertgroup'   => 1);

$t->get_ok("/scot/api/v2/alert/$alert_1_id/event" => {},
    "Get Event(s) that this alert was promoted to")
    ->status_is(200)
    ->json_is('/records/0/id'   => $event1);

$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id" => {},
    "Get Alertgroup $alertgroup_id")
    ->status_is(200)
    ->json_is('/alert_count'    => 2)
    ->json_is('/promoted_count' => 1)
    ->json_is('/closed_count'   => 0)
    ->json_is('/open_count'     => 1);

$t->put_ok("/scot/api/v2/alert/$alert_2_id" => json => 
    {
        promote => $event1,
    } 
)->status_is(200)
 ->json_is('/id'        => $event1)                     
 ->json_is('/status'    => "successfully promoted");    # expect the id of the promoted object

# print Dumper($t->tx->res->json), "\n";
# done_testing();
# exit 0;

$t->get_ok("/scot/api/v2/event/$event1/alert" => {},
    "Get alerts promoted to Event $event1")
    ->status_is(200)
    ->json_is('/queryRecordCount'       => 2)
    ->json_is('/records/0/id'           => $alert_1_id)
    ->json_is('/records/0/status'       => 'promoted')
    ->json_is('/records/0/alertgroup'   => $alertgroup_id)
    ->json_is('/records/1/id'           => $alert_2_id)
    ->json_is('/records/1/status'       => 'promoted')
    ->json_is('/records/1/alertgroup'   => $alertgroup_id);


$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id" => {},
    "Get Alertgroup $alertgroup_id")
    ->status_is(200)
    ->json_is('/alert_count'    => 2)
    ->json_is('/promoted_count' => 2)
    ->json_is('/closed_count'   => 0)
    ->json_is('/open_count'     => 0);


$t->put_ok("/scot/api/v2/event/$event1" => json => 
    {
        promote => "new"
    }
)->status_is(200)
    ->json_is('/id'     =>  $event1)
    ->json_is('/status' =>  "successfully promoted");

my $incident1   = $t->tx->res->json->{id};

$t->get_ok("/scot/api/v2/incident/$incident1/event" => {},
    "Get events promoted to Incident $incident1")
    ->status_is(200)
    ->json_is('/queryRecordCount'       => 1)
    ->json_is('/records/0/id'           => $event1)
    ->json_is('/records/0/status'       => 'promoted');

$t->get_ok("/scot/api/v2/event/$event1/incident" => {},
    "Get alerts promoted to Event $event1")
    ->status_is(200)
    ->json_is('/queryRecordCount'       => 1)
    ->json_is('/records/0/id'           => $incident1);

# print Dumper($t->tx->res->json), "\n";
done_testing();
exit 0;

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 2",
        source  => "footest",
        status  => 'open',
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event2 = $t->tx->res->json->{id};

$t->put_ok("/scot/api/v2/event/$event2" => json => 
    {
        promote => $incident1
    }
)->status_is(200)
    ->json_is('/id'     =>  $event2)
    ->json_is('/status' =>  "successfully promoted")
    ->json_is('/pid'    => $incident1);

$t->get_ok("/scot/api/v2/incident/$incident1/event" => {},
    "Get events promoted to Incident $incident1")
    ->status_is(200)
    ->json_is('/queryRecordCount'       => 2)
    ->json_is('/records/0/id'           => $event1)
    ->json_is('/records/0/status'       => 'promoted')
    ->json_is('/records/0/id'           => $event2)
    ->json_is('/records/0/status'       => 'promoted');


$t->put_ok("/scot/api/v2/event/$event2" => json => 
    {   unpromote => $incident1 }
)   ->status_is(200)
    ->json_is('/id'     => $event2)
    ->json_is('/status' => "successfully unpromoted");
    
$t->get_ok("/scot/api/v2/event/$event2/incident" => {},
            "Checking event $event2")
    ->status_is(200)
    ->json_is('/queryRecordCount'    => 0);

$t->get_ok("/scot/api/v2/incident/$incident/event" => {},
            "Checking event $event2")
    ->status_is(200)
    ->json_is('/queryRecordCount'       => 1)
    ->json_is('/records/0/id'           => $event1)
    ->json_is('/records/0/status'       => 'promoted');
    

# print Dumper($t->tx->res->json), "\n";
done_testing();
exit 0;

