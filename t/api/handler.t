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

my $toddtime    = $env->now();
$t  ->post_ok  ('/scot/api/v2/handler'  => json => {
        username => "tbruner",
        start    => $toddtime - 10,
        end      => $toddtime + 10,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $handler1 = $t->tx->res->json->{id};

$t  ->post_ok  ('/scot/api/v2/handler'  => json => {
        username => "foobar",
        start    => $toddtime + 8,
        end      => $toddtime + 29,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/api/v2/handler?current=1")
    ->status_is(200)
    ->json_is('/records/0/username' => 'tbruner');

print "Current Epoch is : ". $env->now()."\n";
print "\n Sleeping for 10 secods\n";
sleep 10;
print "Current Epoch is : ". $env->now()."\n";


$t  ->get_ok("/scot/api/v2/handler?current=1")
    ->status_is(200)
    ->json_is('/records/0/username' => 'foobar');


$t  ->get_ok("/scot/api/v2/handler?current=$toddtime")
    ->status_is(200)
    ->json_is('/records/0/username' => 'tbruner');

my $tt = $toddtime +8;
$t  ->get_ok("/scot/api/v2/handler?current=$tt")
    ->status_is(200)
    ->json_is('/records/0/username' => 'tbruner')
    ->json_is('/records/1/username' => 'foobar');

 print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



