#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Collection;
use Scot::Collection::Alertgroup;

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.test.log";
$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';

print "Resetting test db...\n";
system("mongo scot-testing <../../install/src/mongodb/reset.js 2>&1 > /dev/null");

@defgroups = ( 'wg-scot-ir', 'test' );

my $t = Test::Mojo->new('Scot');
my $env = Scot::Env->instance;

$t->post_ok(
    '/scot/api/v2/alertgroup'   => json => {
        message_id  => '112233445566778899aabbccddeeff',
        subject     => 'test message 1',
        data        => [
            { foo   => 1,   bar => 2 },
            { foo   => 3,   bar => 4 },
        ],
        tag     => [qw(test testing)],
        source  => [qw(todd scot)],
        columns  => [qw(foo bar) ],
    }
)->status_is(200)
 ->json_is('/id'    => 1);

my $alertgroup_id   = $t->tx->res->json->{id};
my $updated         = $t->tx->res->json->{updated};


$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/alert" => {},
           "Get alertgroup $alertgroup_id" )
    ->status_is(200)
    ->json_is('/totalRecordCount'       => 2)
    ->json_is('/queryRecordCount'       => 2)
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
 ->json_is('/status'    => "ok");

# XXX
#print Dumper($t->tx->res->json), "\n";
#done_testing();
#exit 0;

my $event1  = $t->tx->res->json->{id};

$t->get_ok("/scot/api/v2/event/$event1/entry" => {},
    "Get the entries from the new event" )
    ->status_is(200)
    ->json_is('/records/0/class'    => 'alert')
    ->json_is('/records/0/parent'   => 0 )
    ->json_is('/records/0/children/0/class'    => 'entry')
    ->json_is('/records/0/children/0/parent'    => 1);


# print Dumper($t->tx->res->json), "\n";
# done_testing();
# exit 0;

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
 ->json_is('/id'        => $alert_2_id)                     
 ->json_is('/pid'        => $event1)                     
 ->json_is('/status'    => "ok");    # expect the id of the promoted object


$t->get_ok("/scot/api/v2/event/$event1/entry" => {},
    "Get the entries from the new event" )
    ->status_is(200)
    ->json_is('/records/0/class'    => 'alert')
    ->json_is('/records/0/parent'   => 0 )
    ->json_is('/records/0/children/0/class'    => 'entry')
    ->json_is('/records/0/children/0/parent'    => 1)
    ->json_is('/records/0/children/1/class'     => 'entry')
    ->json_is('/records/0/children/1/parent'     => 1)
    ->json_is('/records/0/children/0/body'  => '<h3>From Alert <a href="/#/alert/1">1</h3><br><h4>test message 1</h4><table class="tablesorter alertTableHorizontal">
<tr>
<th>foo</th><th>bar</th>
</tr>
<tr>
<td>1</td><td>2</td>
</tr>
</table>
');

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
    ->json_is('/status' =>  "ok");

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


$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 2",
        source  => ["footest"],
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
    ->json_is('/status' =>  "ok")
    ->json_is('/pid'    => $incident1);


$t->get_ok("/scot/api/v2/incident/$incident1/event" => {},
    "Get events promoted to Incident $incident1")
    ->status_is(200)
    ->json_is('/queryRecordCount'       => 2)
    ->json_is('/records/0/id'           => $event1)
    ->json_is('/records/0/status'       => 'promoted')
    ->json_is('/records/1/id'           => $event2)
    ->json_is('/records/1/status'       => 'promoted');


#$t->put_ok("/scot/api/v2/event/$event2" => json => 
#    {   unpromote => $incident1 }
#)   ->status_is(200)
#    ->json_is('/id'     => $event2)
#    ->json_is('/status' => "successfully unpromoted");

# print Dumper($t->tx->res->json), "\n";
# done_testing();
# exit 0;
    
#$t->get_ok("/scot/api/v2/event/$event2/incident" => {},
#            "Checking event $event2")
#    ->status_is(200)
#    ->json_is('/queryRecordCount'    => 0);

#$t->get_ok("/scot/api/v2/incident/$incident1/event" => {},
#            "Checking event $event2")
#    ->status_is(200)
#    ->json_is('/queryRecordCount'       => 1)
#    ->json_is('/records/0/id'           => $event1)
#    ->json_is('/records/0/status'       => 'promoted');
    

print Dumper($t->tx->res->json), "\n";
done_testing();
exit 0;

