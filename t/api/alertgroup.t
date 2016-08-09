#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Collection;
use Scot::Collection::Alertgroup;

$ENV{'scot_mode'}           = "testing";
$ENV{'SCOT_AUTH_TYPE'}      = "Testing";
$ENV{'scot_log_file'}       = "/var/log/scot/scot.test.log";
$ENV{'scot_env_configfile'} = '../../../Scot-Internal-Modules/etc/scot_env_test.cfg';

print "Resetting test db...\n";
system("mongo scot-testing <../../etc/database/reset.js 2>&1 > /dev/null");

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
        tag     => [qw(test testing)],
        source  => [qw(todd scot)],
        columns  => [qw(foo bar) ],
    }
)->status_is(200);

my $alertgroup_id   = $t->tx->res->json->{id};
my $updated         = $t->tx->res->json->{updated};


$t->get_ok("/scot/api/v2/alertgroup" => {},
    "Get alertgroup list")
    ->status_is(200)
    ->json_is('/records/0/tag/0'   => 'test')
    ->json_is('/records/0/tag/1'   => 'testing')
    ->json_is('/records/0/source/0'    => 'todd')
    ->json_is('/records/0/source/1'    => 'scot');

#print Dumper($t->tx->res->json), "\n";
#done_testing();
#exit 0;

$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id" => {},
           "Get alertgroup $alertgroup_id" )
  ->status_is(200)
  ->json_is('/subject'      => 'test message 1')
  ->json_is('/views'        => 1)
  ->json_is('/alert_count'  => 2);

$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id" => {},
           "seeing if views increases")
    ->status_is(200)
    ->json_is('/views' => 2) # two gets = 2 views
    ->json_is('/view_history/scot-testing/where'    => '127.0.0.1');

# print Dumper($t->tx->res->json), "\n";
# done_testing();
# exit 0;


$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/alert" => {},
    "Getting alerts in alertgroup")
    ->status_is(200)
    ->json_is('/totalRecordCount'   => 2)
    ->json_is('/queryRecordCount'   => 2)
    ->json_is('/records/0/alertgroup'   => $alertgroup_id)
    ->json_is('/records/1/alertgroup'   => $alertgroup_id)
    ->json_is('/records/0/data/foo'     => 1)
    ->json_is('/records/1/data/foo'     => 3);


my $alert1_id   = $t->tx->res->json->{records}->[0]->{id};
my $alert1_data = $t->tx->res->json->{records}->[0]->{data};
$alert1_data->{boom} = 8;
my $alert2_id   = $t->tx->res->json->{records}->[1]->{id};
my $alert2_data = $t->tx->res->json->{records}->[1]->{data};
$alert2_data->{boom} = 9;

$t->put_ok("/scot/api/v2/alert/$alert1_id" => json => 
    {data => $alert1_data,
     columns => [ qw(foo bar boom) ]}
);
$t->put_ok("/scot/api/v2/alert/$alert2_id" => json => 
    {data => $alert2_data, columns => [ qw(foo bar boom) ]}
);

$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/alert" => {},
    "Getting alerts in alertgroup")
    ->status_is(200)
    ->json_is('/totalRecordCount'   => 2)
    ->json_is('/queryRecordCount'   => 2)
    ->json_is('/records/0/data/boom'     => 8)
    ->json_is('/records/0/columns/2'   => 'boom')
    ->json_is('/records/1/data/boom'     => 9)
    ->json_is('/records/1/columns/2'   => 'boom');

# print Dumper($t->tx->res->json), "\n";
# $t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id" => {},
 #    "Getting alertgroup again to see if stuff is updated")
  #   ->status_is(200);


$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/tag" => {},
    "Getting tags applied to alertgroup")
    ->status_is(200)
    ->json_is('/totalRecordCount'   => 2)
    ->json_is('/queryRecordCount'   => 2);

$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/history" => {},
    "Getting alertgroup history")
    ->status_is(200);

$t  ->post_ok('/scot/api/v2/entry'  => json => {
    body    => "Entry on an alert",
    target_id   => $alert1_id,
    target_type => "alert",
    parent      => 0,
})
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t->get_ok("/scot/api/v2/alert/$alert1_id/entry")
    ->status_is(200)
    ->json_is('/records/0/body'     => 'Entry on an alert')
    ->json_is('/records/0/target/id'  => $alert1_id )
    ->json_is('/records/0/target/type'    => 'alert');

$t->get_ok("/scot/api/v2/alertgroup" => {},
    "checking entry_count in alertgroup listing")
    ->status_is(200);

$t->put_ok("/scot/api/v2/alertgroup/$alertgroup_id" => json =>
    { status => 'closed' } 
)->status_is(200)
 ->json_is("/status" => "successfully updated");


$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/alert" => {},
    "Getting alerts in alertgroup")
    ->status_is(200)
    ->json_is('/totalRecordCount'   => 2)
    ->json_is('/queryRecordCount'   => 2)
    ->json_is('/records/0/status'   => 'closed')
    ->json_is('/records/1/status'   => 'closed');
    
# print Dumper($t->tx->res->json), "\n";
done_testing();
exit 0;

