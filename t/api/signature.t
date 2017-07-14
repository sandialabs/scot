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

my $defgroups       = [ 'wg-scot-ir', 'testing' ];

my $t   = Test::Mojo->new('Scot');

my $body = '
    function test() {
        echo "foo"
    }
';

$t  ->post_ok  ('/scot/api/v2/signature'  => json => {
        name    => 'Test Sig 1',
        type    => 'testsig',
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $sig_id = $t->tx->res->json->{id};

$t  ->post_ok ('/scot/api/v2/sigbody' => json => {
    signature_id => $sig_id,
    body         => $body
})  ->status_is(200)
    ->json_is('/status' => 'ok');
my $bsig1 = $t->tx->res->json->{id};

# print Dumper($t->tx->res->json);
# done_testing();
# exit 0;

$t  ->get_ok("/scot/api/v2/sigbody/$bsig1")
    ->status_is(200);

my $bsig1rev = $t->tx->res->json->{revision};


$t  ->get_ok    ("/scot/api/v2/signature/$sig_id")
    ->status_is(200)
    ->json_is('/name'   => 'Test Sig 1')
    ->json_is('/type'   => 'testsig')
    ->json_is("/version/$bsig1rev/body" => $body)
    ->json_is('/status' => "disabled");

$t  ->put_ok    ("/scot/api/v2/signature/$sig_id" => json => {
    name    => "updated Test Sig 1",
    status  => "enabled",
})  ->status_is(200)
    ->json_is('/status' => "ok");

$t  ->get_ok    ("/scot/api/v2/signature/$sig_id")
    ->status_is(200)
    ->json_is('/name'   => 'updated Test Sig 1')
    ->json_is('/status' => 'enabled');

# add another version body
sleep 1;
$t  ->post_ok    ("/scot/api/v2/sigbody" => json => {
    body            =>  "new signature foobar",
    signature_id    => $sig_id,
})  ->status_is(200)
    ->json_is('/status' => "ok");

my $bsig2 = $t->tx->res->json->{id};
$t  ->get_ok("/scot/api/v2/sigbody/$bsig2")
    ->status_is(200);

my $bsig2rev = $t->tx->res->json->{revision};

print "\n\n bsig2rev = $bsig2rev\n\n";

$t  ->get_ok    ("/scot/api/v2/signature/$sig_id")
    ->status_is(200)
    ->json_is('/name'   => 'updated Test Sig 1')
    ->json_is("/version/$bsig2rev/body" => "new signature foobar")
    ->json_is("/version/$bsig1rev/body" => $body)
    ->json_is('/status' => "enabled");

$t  ->get_ok("/scot/api/v2/signature/$sig_id/history")
    ->status_is(200)
    ->json_is("/records/0/what" => "created via api")
    ->json_is("/records/0/target/id" => 1)
    ->json_is("/records/1/what" => "Signature status change to enabled")
    ->json_is("/records/1/target/id" => 1);



# print Dumper($t->tx->res->json);
done_testing();
exit 0;



