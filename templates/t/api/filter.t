#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Mojo::JSON qw(decode_json encode_json);


$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.test.log";
$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';

print "Resetting test db...\n";
system("mongo scot-testing <../../install/src/mongodb/reset.js 2>&1 > /dev/null");

my @defgroups       = ( 'wg-scot-ir', 'testing' );

my $t   = Test::Mojo->new('Scot');

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 1",
        source  => ["firetest"],
        tag     => ['test'],
        status  => 'open',
#        readgroups  => $defgroups,
#        modifygroups=> $defgroups,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_id = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/event/$event_id?tag=test&tag=!foo")
    ->status_is(200)
    ->json_is('/id'     => $event_id)
    ->json_is('/owner'  => 'scot-testing')
    ->json_is('/status'  => 'open')
    ->json_is('/subject' => 'Test Event 1');

$t  ->get_ok("/scot/api/v2/event/$event_id?subject=vent")
    ->status_is(200)
    ->json_is('/id'     => $event_id)
    ->json_is('/owner'  => 'scot-testing')
    ->json_is('/status'  => 'open')
    ->json_is('/subject' => 'Test Event 1');

$t  ->get_ok("/scot/api/v2/event/$event_id?created=1472228309,1473228310")
    ->status_is(200)
    ->json_is('/id'     => $event_id)
    ->json_is('/owner'  => 'scot-testing')
    ->json_is('/status'  => 'open')
    ->json_is('/subject' => 'Test Event 1');

$t  ->get_ok("/scot/api/v2/event/$event_id?views=2<=x<=4")
    ->status_is(200)
    ->json_is('/id'     => $event_id)
    ->json_is('/owner'  => 'scot-testing')
    ->json_is('/status'  => 'open')
    ->json_is('/subject' => 'Test Event 1');

$t  ->get_ok("/scot/api/v2/event/$event_id?views=2")
    ->status_is(200)
    ->json_is('/id'     => $event_id)
    ->json_is('/owner'  => 'scot-testing')
    ->json_is('/status'  => 'open')
    ->json_is('/subject' => 'Test Event 1');

$t  ->get_ok("/scot/api/v2/event/$event_id?created=1472228309&created=1473228310")
    ->status_is(200)
    ->json_is('/id'     => $event_id)
    ->json_is('/owner'  => 'scot-testing')
    ->json_is('/status'  => 'open')
    ->json_is('/subject' => 'Test Event 1');
print Dumper($t->tx->res->json);
done_testing();
exit 0;

