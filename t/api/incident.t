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
        status  => 'open',
        groups      => $defgroups,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_id = $t->tx->res->json->{id};

$t  ->post_ok('/scot/api/v2/incident' => json => {
        events  => [ $event_id ],
        status      => 'open',
        category    => 'IMI-1',
        sensitivity => 'very',
        occurred    => 1444309925,
        discovered    => 1444319925,
        groups      => $defgroups,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $incident1 = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/incident/$incident1")
    ->status_is(200)
    ->json_is('/occurred'   => 1444309925)
    ->json_is('/events/0'   => $event_id);

$t  ->post_ok('/scot/api/v2/entry'  => json => {
        body        => "incident entry one",
        target_id   => $incident1,
        target_type => 'incident',
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/api/v2/incident/$incident1/entry")
    ->status_is(200)
    ->json_is('/records/0/body'   => "incident entry one")
    ->json_is('/records/0/target/id'  => 1)
    ->json_is('/records/0/target/type'    => 'incident');


 print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



