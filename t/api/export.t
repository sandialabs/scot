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

$t  ->post_ok('/scot/api/v2/entry' => json => {
        body        => "Entry 1 on Event $event_id",
        target_id   => $event_id,
        target_type => "event",
        groups      => $defgroups, 
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry1 = $t->tx->res->json->{id};

$t  ->post_ok('/scot/api/v2/entry' => json => {
        body        => "Entry 2 on Event $event_id",
        target_id   => $event_id,
        target_type => "event",
        groups      => $defgroups, 
        parent      => $entry1,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry2 = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/export/event/$event_id")
    ->status_is(200);

 print Dumper($t->tx->res->json), "\n";
 done_testing();
 exit 0;



