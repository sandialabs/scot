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

my @defgroups       = ( 'wg-scot-ir', 'testing' );

my $t   = Test::Mojo->new('Scot');

$t  ->post_ok  ('/scot/api/v2/dispatch'  => json => {
        subject => "Test Dispatch 1",
        source  => ["Guy in Fedora"],
        source_uri => 'http://foobar.com',
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $intel1 = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/dispatch/$intel1")
    ->json_is('/id' => $intel1)
    ->json_is('/subject' => 'Test Dispatch 1')
    ->json_is('/source_uri' => 'http://foobar.com')
    ->status_is(200);



#  print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



