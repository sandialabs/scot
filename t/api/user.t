#!/usr/bin/env perl

use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Env;
use Mojo::JSON qw(decode_json encode_json);

$ENV{'scot_mode'}   = "testing";
$ENV{'SCOT_AUTH_TYPE'}   = "Testing";
$ENV{'scot_env_configfile'} = '../../../Scot-Internal-Modules/etc/scot_env_test.cfg';
print "Resetting test db...\n";
system("mongo scot-testing <../../etc/database/reset.js 2>&1 > /dev/null");

my @defgroups       = ( 'wg-scot-ir', 'testing' );

my $t   = Test::Mojo->new('Scot');

my $env = Scot::Env->instance;

$t  ->post_ok  ('/scot/api/v2/user'  => json => {
        username    => "tbruner",
        lockouts    => 0,
        attempts    => 0,
        last_login_attempt  => time(),
        fullname    => "Todd Bruner",
        tzpref      => "MST",
        lastvisit   => time(),
        last_activity_check => time(),
        groups      => [],
        active      => 1,
        local_acct  => 1,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $user1 = $t->tx->res->json->{id};


$t  ->get_ok("/scot/api/v2/user")
    ->status_is(200)
    ->json_is('/records/0/username' => 'tbruner');


$t  ->get_ok("/scot/api/v2/user/$user1")
    ->status_is(200)
    ->json_is('/username' => 'tbruner');

$t  ->put_ok("/scot/api/v2/user/$user1" => json =>
            { groups    => [ 'foo', 'bar' ] })
    ->status_is(200);

$t  ->get_ok("/scot/api/v2/user/$user1")
    ->status_is(200)
    ->json_is('/username' => 'tbruner')
    ->json_is('/groups/0'   => 'foo')
    ->json_is('/groups/1'   => 'bar');

 print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



