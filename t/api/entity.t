#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '../../lib';

use HTML::Entities;
use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Env;
use Parallel::ForkManager;
use Mojo::JSON qw(decode_json encode_json);
use Scot::App::Responder::Flair;

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.test.log";
$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';

print "Resetting test db...\n";
system("mongo scot-testing <../../install/src/mongodb/reset.js 2>&1 > /dev/null");

my @defgroups       = ( 'wg-scot-ir', 'testing' );

foreach my $k (keys %ENV) {
    next unless $k =~ /scot/i;
    print "$k = $ENV{$k}\n";
}

my $t       = Test::Mojo->new('Scot');
my $env     = Scot::Env->instance;
my $flairer = Scot::App::Responder::Flair->new({env=>$env});

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 1",
        source  => ["firetest"],
        status  => 'open',
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_id = $t->tx->res->json->{id};

$t  ->post_ok('/scot/api/v2/entry'    => json => {
        body        => qq| 
            google.com was providing 10.12.14.16 as the ipaddress
        |,
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups => $defgroups,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry2  = $t->tx->res->json->{id};
$flairer->process_message(undef, {
    action  => "created", 
    data    => {
        type    => "entry", 
        id      => $entry2
    },
});

$t  ->get_ok("/scot/api/v2/entry/$entry2")
    ->status_is(200);

my $entrydata = $t->tx->res->json;

$t  ->get_ok("/scot/api/v2/event/$event_id/entity")
    ->status_is(200)
    ->json_is('/totalRecordCount' => 2)
    ->json_is('/records/google.com/type'   => 'domain')
    ->json_is('/records/10.12.14.16/type'   => 'ipaddr');

# print Dumper($t->tx->res->json);
# done_testing();
# exit 0;

my $googleid = $t->tx->res->json->{records}->{'google.com'}->{id};
my $ipid     = $t->tx->res->json->{records}->{'10.12.14.16'}->{id};


$t  ->get_ok("/scot/api/v2/entity/$googleid/event")
    ->status_is(200)
    ->json_is('/records/0/id'       => 1)
    ->json_is('/records/0/subject'  => 'Test Event 1');
    
$t  ->get_ok("/scot/api/v2/entity/$ipid/event")
    ->status_is(200)
    ->json_is('/records/0/id'       => 1)
    ->json_is('/records/0/subject'  => 'Test Event 1');

$t  ->post_ok('/scot/api/v2/entry'  => json => {
    body    => qq|
        chosun.com apture.com and cnomy.com
    |,
    target_id   => $event_id,
    target_type => "event",
    parent      => 0,
})->status_is(200)
    ->json_is('/status' => 'ok');

my $sidd_entry_id = $t->tx->res->json->{id};
$flairer->process_message(undef, {
    action  => "created", 
    data    => {
        type    => "entry", 
        id      => $sidd_entry_id
    }
});

$t->get_ok("/scot/api/v2/entry/$sidd_entry_id/entity")
    ->status_is(200)
    ->json_is('/totalRecordCount'   => 3)
    ->json_is('/records/chosun.com/type'    => 'domain');

 print Dumper($t->tx->res->json),"\n";
 done_testing();
 exit 0;

my $eid1 = $t->tx->res->json->{records}->{'chosun.com'}->{id};
my $eid2 = $t->tx->res->json->{records}->{'apture.com'}->{id};
my $eid3 = $t->tx->res->json->{records}->{'cnomy.com'}->{id};

$t->get_ok("/scot/api/v2/entity/$eid1")
    ->status_is(200);

my $agdata = [
            { foo   => 'cnn.com',   bar => '2.2.2.2' },
            { foo   => 'reddit.com',   bar => '4.4.4.4' },
            { foo   => 'foo.com',   bar => '10.12.14.16' },
        ];

$t->post_ok(
    '/scot/api/v2/alertgroup'   => json => {
        message_id  => '112233445566778899aabbccddeeff',
        subject     => 'test message 1',
        data        => $agdata,
        tag     => [qw(test testing)],
        source  => [qw(todd scot)],
        columns  => [qw(foo bar) ],
    }
)->status_is(200);
my $alertgroup_id   = $t->tx->res->json->{id};
$flairer->process_message(undef, {
    action  => "created", 
    data    => {
        type    => "alertgroup", 
        id      => $alertgroup_id
    }
});

$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/alert")
    ->status_is(200);


$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/entity")
->status_is(200);

# test entity attribute filter
$t->get_ok("/scot/api/v2/entity?columns=id")
    ->status_is(200);

my $result = $t->tx->res->json;

ok(keys %{$result->{records}->[0]} == 1, "only one attr per record");
ok($result->{records}->[0]->{id} == 1, "id is correct");

$t->get_ok("/scot/api/v2/entity/byname?name=chosun.com")
    ->status_is(200);

# create entity via api

$t->post_ok(
    '/scot/api/v2/entity'   => json => {
        value   => "10.170.217.202",
        type    => "ipaddr",
        data    => {
            "sidd2" => {
                "FOOB"  => {
                    count   => 1,
                    first   => "2018-03-15 19:01:04",
                    highestpriority => "low",
                    lastpriority    => "low",
                    latest          => "2018-03-15 19:01:04",
                },
                "comment"   => [
                    {
                        when    => "2018-03-15 19:01:04",
                        where   => "zbl3",
                        who     => "FOOB",
                        why     => "malware domain. FOOB CSIRT Ticket 99993",
                    }
                ],
                history     => [
                    {
                        what    => "zbl3:Identifier submitted by FOOB",
                        when    => "2018-03-15 19:47:33.012233",
                    }
                ],
                indentifier => "10.170.217.202",
                index       => [],
                meta        => {},
                modified    => "2018-03-15 19:47:33.012233",
                site        => "FOOB",
                sitesadded  => 1,
                tags        => [ "zbl3.FOOB.1521140444" ],
                timesadded  => 1,
                type        => "IPv4",
            },
        }
    }
)->status_is(200);



 print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



