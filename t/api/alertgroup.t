#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Collection;
use Scot::Collection::Alertgroup;
use Mojo::JSON qw(encode_json decode_json);
use Scot::App::Responder::Flair;

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.test.log";
$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';

print "Resetting test db...\n";
system("mongo scot-testing <../../install/src/mongodb/reset.js 2>&1 > /dev/null");

@defgroups = ( 'ir', 'test' );

foreach my $k (keys %ENV) {
    next unless $k =~ /scot/;
    print "$k = $ENV{$k}\n";
}

my $t = Test::Mojo->new('Scot');
my $env = Scot::Env->instance;
#my $amq = $env->amq;
#$amq->subscribe("alert", "alert_queue");
#$amq->get_message(sub{
#    my ($self, $frame) = @_;
#    print "AMQ received: ". Dumper($frame). "\n";
#});

# use this to set csrf protection 
# though not really used due to testing auth 

my $flairer = Scot::App::Responder::Flair->new({
    config_file => "../../../Scot-Internal-Modules/etc/flair.cfg.pl"
});

$t->ua->on(start => sub {
    my ($ua, $tx) = @_;
    $tx->req->headers->header('X-Requested-With' => 'XMLHttpRequest');
});


$t->post_ok(
    '/scot/api/v2/alertgroup'   => json => {
        message_id  => '112233445566778899aabbccddeeff',
        subject     => 'test message 1',
        data        => [
            { foo   => 1,   bar => 2, data => "10.10.10.1" },
            { foo   => 3,   bar => 4, data => "10.10.10.2"},
        ],
        tag     => [qw(test testing)],
        source  => [qw(todd scot)],
        columns  => [qw(foo bar data) ],
    }
)->status_is(200);

my $alertgroup_id   = $t->tx->res->json->{id};
my $updated         = $t->tx->res->json->{updated};
$flairer->process_message(undef, {
    action  => "created",
    data    => {
        type    => "alertgroup",
        id      => $alertgroup_id
    }
});

$t->get_ok("/scot/api/v2/alertgroup" => {},
    "Get alertgroup list")
    ->status_is(200)
    ->json_is('/records/0/tag/0'   => 'test')
    ->json_is('/records/0/tag/1'   => 'testing')
    ->json_is('/records/0/source/0'    => 'todd')
    ->json_is('/records/0/source/1'    => 'scot');


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

$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/entity" => {},
    "Get alertgroup entity list")
    ->status_is(200)
    ->json_is('/totalRecordCount'   => 2)
    ->json_is('/queryRecordCount'   => 2)
    ->json_is('/records/10.10.10.2/type' => "ipaddr")
    ->json_is('/records/10.10.10.1/type' => "ipaddr");

#  print Dumper($t->tx->res->json), "\n";
#  done_testing();
#  exit 0;

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
 ->json_is("/status" => "ok");

$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/alert" => {},
    "Getting alerts in alertgroup")
    ->status_is(200)
    ->json_is('/totalRecordCount'   => 2)
    ->json_is('/queryRecordCount'   => 2)
    ->json_is('/records/0/status'   => 'closed')
    ->json_is('/records/1/status'   => 'closed');

# create a bunch of alertgroups to test sorting and filtering

my @ags = (
    {
        message_id  => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        subject     => 'test message 3',
        data        => [
            { foo   => 1,   bar => 10, boom => "one" },
            { foo   => 1,   bar => 10, boom => "one" },
            { foo   => 1,   bar => 10, boom => "one" },
            { foo   => 1,   bar => 10, boom => "one" },
            { foo   => 1,   bar => 10, boom => "one" },
            { foo   => 1,   bar => 10, boom => "one" },
            { foo   => 1,   bar => 10, boom => "one" },
        ],
        tag     => [qw(test testing)],
        source  => [qw(todd scot)],
        columns  => [qw(foo bar boom) ],
    },
    {
        message_id  => 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        subject     => 'test message 4',
        data        => [
            { foo   => 2,   bar => 20, boom => "two" },
            { foo   => 2,   bar => 20, boom => "two" },
            { foo   => 1,   bar => 10, boom => "one" },
            { foo   => 1,   bar => 10, boom => "one" },
            { foo   => 1,   bar => 10, boom => "one" },
            { foo   => 1,   bar => 10, boom => "one" },
        ],
        tag     => [qw(test testing)],
        source  => [qw(todd scot)],
        columns  => [qw(foo bar boom) ],
    },
    {
        message_id  => 'cccccccccccccccccccccccccccccc',
        subject     => 'test message 5',
        data        => [
            { foo   => 3,   bar => 30, boom => "three" },
            { foo   => 3,   bar => 30, boom => "three" },
            { foo   => 3,   bar => 30, boom => "three" },
            { foo   => 3,   bar => 30, boom => "three" },
        ],
        tag     => [qw(test testing)],
        source  => [qw(todd scot)],
        columns  => [qw(foo bar boom) ],
    },
    {
        message_id  => 'dddddddddddddddddddddddddddddd',
        subject     => 'fest test message 6',
        data        => [
            { foo   => 4,   bar => 40, boom => "four" },
            { foo   => 4,   bar => 40, boom => "four" },
        ],
        tag     => [qw(test testing)],
        source  => [qw(todd scot)],
        columns  => [qw(foo bar boom) ],
    },
    {
        message_id  => 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
        subject     => 'fest test message 7',
        data        => [
            { foo   => 5,   bar => 50, boom => "five" },
        ],
        tag     => [qw(test testing)],
        source  => [qw(todd scot)],
        columns  => [qw(foo bar boom) ],
    },
    {
        message_id  => 'ffffffffffffffffffffffffffffff',
        subject     => 'fest test message 8',
        data        => [
            { foo   => 6,   bar => 60, boom => "six" },
        ],
        tag     => [qw(test testing)],
        source  => [qw(todd scot)],
        columns  => [qw(foo bar boom) ],
    },
);

foreach my $ag (@ags) {
    $t->post_ok(
        '/scot/api/v2/alertgroup'   => json => $ag
    )->status_is(200);
}


my $json_sort   = encode_json {
    id  => -1
};

$t->get_ok("/scot/api/v2/alertgroup" => 
            {} => 
            form => {
                sort    => $json_sort
            }, 
    "Get alertgroup list")
    ->status_is(200)
    ->json_is('/records/0/id'   => 7)
    ->json_is('/records/6/id'   => 1);

$t->get_ok("/scot/api/v2/alertgroup" => 
            {} => 
            form => {
                sort    => "-id",
            }, 
    "Get alertgroup list")
    ->status_is(200)
    ->json_is('/records/0/id'   => 7)
    ->json_is('/records/6/id'   => 1);
#XXX
#print Dumper($t->tx->res->json), "\n";
#done_testing();
#exit 0;
$t->get_ok("/scot/api/v2/alertgroup" => 
            {} => 
            form => {
                sort    => $json_sort,
                limit   => 2,
            })
    ->status_is(200)
    ->json_is('/queryRecordCount'   => 2)
    ->json_is('/totalRecordCount'   => 7)
    ->json_is('/records/0/id'   => 7)
    ->json_is('/records/1/id'   => 6);

$t->get_ok("/scot/api/v2/alertgroup" => 
            {} => 
            form => {
                sort    => $json_sort,
                limit   => 2,
                offset  => 2,
            }, 
    )
    ->status_is(200)
    ->json_is('/queryRecordCount'   => 2)
    ->json_is('/totalRecordCount'   => 7)
    ->json_is('/records/0/id'       => 5)
    ->json_is('/records/1/id'       => 4);

my $json_match = encode_json { subject => "fest" };

$t->get_ok("/scot/api/v2/alertgroup" => {},
            form => {
                sort    => $json_sort,
                subject => "fest",
                limit   => 2,
                offset  => 2,
            }, 
    )
    ->status_is(200)
    ->json_is('/queryRecordCount'   => 2)
    ->json_is('/totalRecordCount'   => 7);

print Dumper($t->tx->res->json), "\n";
done_testing();
exit 0;

$t->get_ok("/scot/api/v2/alertgroup/7")
    ->status_is(200);
$t->get_ok("/scot/api/v2/alertgroup/7")
    ->status_is(200);
$t->get_ok("/scot/api/v2/alertgroup/7")
    ->status_is(200);
$t->get_ok("/scot/api/v2/alertgroup/6")
    ->status_is(200);
$t->get_ok("/scot/api/v2/alertgroup/6")
    ->status_is(200);
$t->get_ok("/scot/api/v2/alertgroup/5")
    ->status_is(200);

$json_sort  = encode_json { views => -1 };
$t->get_ok("/scot/api/v2/alertgroup" => {},
            form => {
                sort    => $json_sort,
                limit   => 3,
            }, 
    )
    ->status_is(200)
    ->json_is('/queryRecordCount'   => 3)
    ->json_is('/totalRecordCount'   => 7)
    ->json_is('/records/0/views'    => 3)
    ->json_is('/records/1/views'    => 2)
    ->json_is('/records/2/views'    => 2);


$json_match = encode_json { views   => 3 };
$t->get_ok("/scot/api/v2/alertgroup" => {},
            form => {
                views => 3
            }, 
    )
    ->status_is(200);

$t->get_ok("/scot/api/v2/alertgroup/7/alert")
    ->status_is(200);

my $alert_id    = $t->tx->res->json->{records}->[0]->{id};
my $a_e_count   = $t->tx->res->json->{records}->[0]->{entry_count};

$t->post_ok("/scot/api/v2/entry" => json => {
        body    => "Test Entry on alert $alert_id",
        target_id   => $alert_id,
        target_type => "alert",
    })->status_is(200)
    ->json_is('/status' => 'ok');

$t->get_ok("/scot/api/v2/alertgroup/7/alert")
    ->status_is(200)
    ->json_is('/records/0/entry_count' => $a_e_count +1);

# new style multi column sorting
$t->get_ok("/scot/api/v2/alertgroup" => {} ,
            form => { 
                sort    => [qw(-alert_count +view_count)],
                limit   => 3,
            },
        )->status_is(200);

$t->get_ok("/scot/api/v2/alertgroup" => {},
            form    => {
                id  => [1,3,5],
            }
        )->status_is(200);

# test the creation of a alertgroup with 300 alerts, should split

$t->post_ok(
    '/scot/api/v2/alertgroup'   => json => {
        message_id  => '202233445566778899aabbccddeeff',
        subject     => 'test message 202',
        data        => [
            { foo   => 1,   bar => 4 },
            { foo   => 2,   bar => 4 },
            { foo   => 3,   bar => 4 },
            { foo   => 4,   bar => 4 },
            { foo   => 5,   bar => 4 },
            { foo   => 6,   bar => 4 },
            { foo   => 7,   bar => 4 },
            { foo   => 8,   bar => 4 },
            { foo   => 9,   bar => 4 },
            { foo   => 10,   bar => 4 },
            { foo   => 11,   bar => 4 },
            { foo   => 12,   bar => 4 },
        ],
        tag     => [qw(test testing)],
        source  => [qw(todd scot)],
        columns  => [qw(foo bar) ],
    }
)->status_is(200);

    
 print Dumper($t->tx->res->json), "\n";
done_testing();
exit 0;

