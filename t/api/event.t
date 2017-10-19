#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '../../lib';

use v5.18;
use Test::More;
use Test::Mojo;
use Test::Deep;
use Data::Dumper;
use Mojo::JSON qw(decode_json encode_json);

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.test.log";
$ENV{'scot_config_paths'}   = '../../../Scot-Internal-Modules/etc';
$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';

print "Resetting test db...\n";
system("mongo scot-testing <../../install/src/mongodb/reset.js 2>&1 > /dev/null");

use Safe;
no strict 'refs';
my $container	= new Safe 'MCONFIG';
my $result	= $container->rdo($ENV{scot_config_file});
my $hashname	= 'MCONFIG::environment';
my %copy	= %$hashname;
my $config_href = \%copy;
use strict 'refs';

my $defgroups       = $config_href->{default_groups};

my $t   = Test::Mojo->new('Scot');

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 1",
        source  => ["firetest"],
        tag     => ['test'],
        status  => 'open',
        groups      => $defgroups, 
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_id = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/event/$event_id?tag=test,foo")
    ->status_is(200)
    ->json_is('/id'     => $event_id)
    ->json_is('/owner'  => 'scot-testing')
    ->json_is('/status'  => 'open')
    ->json_is('/subject' => 'Test Event 1');

my $orig_updated    = $t->tx->res->json->{updated};

$t  ->get_ok("/scot/api/v2/event/$event_id/source")
    ->status_is(200)
    ->json_is("/records/0/value"  => "firetest");

$t  ->post_ok('/scot/api/v2/entry' => json => {
        body        => "Entry 1 on Event $event_id",
        target_id   => $event_id,
        target_type => "event",
        groups      => $defgroups, 
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry1 = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200)
    ->json_is('/id' => $event_id)
    ->json_is('/owner'  => 'scot-testing')
    ->json_is('/status'  => 'open')
    ->json_is('/subject'    => 'Test Event 1');

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 2",
        source  => ["foobar"],
        groups  => $defgroups, 
        alert_id    => 2,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_2 = $t->tx->res->json->{id};

#my $cols    = encode_json([qw(event_id updated created)]);
#my $filter  = encode_json({id   => {'$in' => [ $event_id, $event_2 ]}});
my $sort    = encode_json {id => -1};
my $url     = "/scot/api/v2/event"; # ?columns=$cols&match=$filter&sort=$grid";
my $form    = {
    sort    => $sort,
    id      => [ $event_id, $event_2 ],
    columns => [qw(id updated created)],
};

$t  ->get_ok($url   => 
             {}     =>
             form   => $form)
    ->status_is(200)
    ->json_is('/records/0/id'    => $event_2)
    ->json_is('/records/1/id'    => $event_id);

my $update2time = $t->tx->res->json->{data}->[1]->{updated};

# XXX
# print Dumper($t->tx->res->json);
# done_testing();
# exit 0;

sleep 1;
print "waking from sleep\n";

$t  ->post_ok  ('/scot/api/v2/event'  => json =>{
        subject => "Test Event x",
        source  => ["foobar"],
        groups  => {
            read   => ['super-secrect'],
            modify => ['super-duper-secret'],
        },
        alert_id    => 3,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_x = $t->tx->res->json->{id};


my $tx  = $t->ua->build_tx(
    PUT => "/scot/api/v2/event/$event_x" => json => {
    owner   => "boombaz",
});
$t  ->request_ok($tx)
    ->status_is(403);

# print Dumper($t->tx->res->json);
# done_testing();
# exit 0;

$tx  = $t->ua->build_tx(
    PUT     => "/scot/api/v2/event/$event_2" => json => {
    status  => "closed",
});

$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/api/v2/event/$event_2")
    ->status_is(200)
    ->json_is('/status'    => "closed");

isnt $t->tx->res->json->{updated}, $update2time, "update time change";


$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 3",
        source  => ["deltest"] ,
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
        alert_id    => 2,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');
    
my $event_3 = $t->tx->res->json->{id};

$t  ->delete_ok("/scot/api/v2/event/$event_3")
    ->status_is(200)
    ->json_is('/status' => 'ok');

sleep 1;

$t  ->post_ok('/scot/api/v2/entry'    => json => {
        body        => "The fifth symphony",
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups => $defgroups,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry2  = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200);
my $updatedbyentry = $t->tx->res->json->{updated};

ok($updatedbyentry > $orig_updated, "Updated was updated");

$t  ->get_ok("/scot/api/v2/event/$event_id/entry")
    ->status_is(200)
    ->json_is('/totalRecordCount' => 2)
    ->json_is('/records/0/id'   => $entry1)
    ->json_is('/records/1/id'   => $entry2);


my $tx  = $t->ua->build_tx(
    PUT =>"/scot/api/v2/event/$event_id" => json =>{
    tag  => ["foo","boo"],
});


$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');


$t->get_ok("/scot/api/v2/event/$event_id/tag")
    ->status_is(200);
#    ->json_is('/records/0/value' => "foo")
#    ->json_is('/records/1/value' => "boo");

my @got_tags        = map { $_->{value} } @{$t->tx->res->json->{records}};
cmp_deeply(\@got_tags, bag(qw(foo boo)), "Got correct tags");

# print Dumper($t->tx->res->json);
# done_testing();
# exit 0;

$t->get_ok("/scot/api/v2/event/$event_id")
    ->status_is(200);
my $new_updated = $t->tx->res->json->{updated};

ok($new_updated > $orig_updated, "Updated was updated");





 print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



