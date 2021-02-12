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

my $data    = {
    name    => "foobar",
    uri     => "https://www.foobar.com/feed",
    type    => "rss",
    status  => "active",
};

$t  ->post_ok  ('/scot/api/v2/feed'  => json => $data)
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $feed1 = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/feed/$feed1")
    ->json_is("/name" => $data->{name})
    ->json_is("/uri"  => $data->{uri})
    ->json_is("/type" => $data->{type})
    ->json_is("/status" => $data->{status})
    ->json_is("/article_count" => 0)
    ->status_is(200);



#  print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



