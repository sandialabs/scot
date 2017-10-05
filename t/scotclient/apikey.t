#!/usr/bin/env perl

use lib '../../lib';
use Test::More;
use Test::Deep;
use Scot::Env;
use Scot::Util::ScotClient;
use Data::Dumper;
use Test::Mojo;
use v5.18;

$ENV{'scot_mode'}       = "testing";
$ENV{'scot_logfile'}    = "/var/log/scot/scot.test.log";
$ENV{'scot_config_file'}= "./scot.test.cfg.pl";

my $t       = Test::Mojo->new('Scot');
my $env     = Scot::Env->instance;
my $apikey  = "12345678901234567890";

my $mongo   = $env->mongo;
my $col     = $mongo->collection('Apikey');
my $obj     = $col->create({
    username    => "tbruner",
    apikey      => $apikey,
    groups      => [ 'wg-scot-api' ],
    active      => 1,
});

ok(defined($env), "Env is defined");

my $client  = Scot::Util::ScotClient->new(
    log     => $env->log,
    api_key => $apikey,
    config  => {
        servername  => $env->servername,
        serverport  => $env->serverport,
        http_method => $env->http_method,
        auth_type   => $env->auth_type,
    }
);

ok(defined($client), "Client defined");
ok(ref($client) eq "Scot::Util::ScotClient", "Client of right type");

# get thing test

my $json = $client->get('event/1');
is($json->{subject}, "SNL Old school attack 1", "Got correct event");
is($json->{created}, 1274387742, "Created time correct");

done_testing();
exit 0;
# get subthing tests

$json = $client->get('event/1/entry');

my $records = $json->{records};
is( ref($records), "ARRAY", "Got an Array" );
is( ref($records->[0]), "HASH", "Element 0 is Hash");
is( $records->[0]->{target}->{type}, "event", "Correct target type");
is( $records->[0]->{target}->{id}, 1, "Correct target id");

# get many things

$json = $client->get('entity');
is( $json->{queryRecordCount}, 50, "Got 50 records back");
is( $json->{records}->[49]->{id}, 50, "Got correct id");

# get many more things
$json = $client->get('entity?limit=100');
is( $json->{queryRecordCount}, 100, "Got 100 records back");

# and less
$json = $client->get('entity?limit=10');
is( $json->{queryRecordCount}, 10, "Got 10 records back");

# timerange get
$json = $client->get('event?created=1484956800&created=1485129599');
is ( $json->{queryRecordCount}, 1, "Got the one event from 1/21/2017 to 1/22/2017");

# matching a number
$json = $client->get('event?views=10');
is( $json->{queryRecordCount}, 50, "Got a bunch of events with view 10");
is( $json->{totalRecordCount}, 332, "The right amount in fact");

# matching a set
$json = $client->get('intel?entry_count=11&entry_count=13&entry_count=17');
is( $json->{totalRecordCount}, 3, "Got the Intel records with 11,13, or 17 entries");

$json = $client->get("alertgroup?alert_count=!1");
is( $json->{totalRecordCount}, 106189, "Got the right number of alertgroups that have more than 1 alert");

$json = $client->get("event?views=4<x<8");
is( $json->{totalRecordCount}, 853, "Got right number of events with between 4 and 8 views (exclusive)");

$json = $client->get("event?tag=email&tag=malware&tag=!false_positive");
is( $json->{totalRecordCount}, 2, "Got right number of events tagged with malware and email, but not false_positive");

# create an alertgroup
$json = $client->post("alertgroup",{
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
);
my $alertgroup_id = $json->{id};
is( $json->{status}, "ok", "Created Alertgroup $alertgroup_id");

$json = $client->get("alertgroup/$alertgroup_id/alert");
$records = $json->{records};

$json = $client->put("alert/".$records->[0]->{id},{
    data    => {
        foo => 11, bar => 22
    }
});

$json = $client->get("alert/".$records->[0]->{id});
is( $json->{data}->{foo}, 11, "data.foo was updated");

# delete the alertgroup
$json = $client->delete("alertgroup/$alertgroup_id");
is( $json->{status}, "ok", "Deleted Alertgroup $alertgroup_id");

say Dumper($json);

done_testing();
exit 0;
