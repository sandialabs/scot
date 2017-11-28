#!/usr/bin/env perl

use lib '../../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Env;
use Mojo::JSON qw(decode_json encode_json);

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.test.log";
$ENV{'scot_config_paths'}   = '../../../Scot-Internal-Modules/etc';
$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';

print "Resetting test db...\n";
system("mongo scot-testing <../../install/src/mongodb/reset.js 2>&1 > /dev/null");

my @defgroups       = ( 'wg-scot-ir', 'testing' );

my $t   = Test::Mojo->new('Scot');

my $env = Scot::Env->instance;

$t  ->post_ok  ('/scot/api/v2/group'  => json => {
        name        => "wg-scot-test",
        description => "The test group",

    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $group1 = $t->tx->res->json->{id};

$t  ->post_ok  ('/scot/api/v2/group'  => json => {
        name        => "wg-scot-test-2",
        description => "The test group 2",

    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $group2 = $t->tx->res->json->{id};


$t  ->get_ok("/scot/api/v2/group")
    ->status_is(200)
    ->json_is('/records/0/name' => 'wg-scot-test')
    ->json_is('/records/1/name' => 'wg-scot-test-2');


$t  ->get_ok("/scot/api/v2/group/$group1")
    ->status_is(200)
    ->json_is('/name' => 'wg-scot-test');


$t  ->get_ok("/scot/api/v2/group/$group1")
    ->status_is(200)
    ->json_is('/description' => 'The test group');

 print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



