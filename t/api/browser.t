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

my $t   = Test::Mojo->new('Scot');

$t  ->post_ok ('/scot/api/v2/entity' => json => {
        "value" => "10.10.10.1",
        "classes" => [ "scanner foobar" ],
        "when" => 1295650258,
        "id" => 6129,
        "type" => "ipaddr",
        "data" => {
            "splunk" => {
                "data" => {
                    "title" => "Search on Splunk",
                    "url" => "https://splunk.sandia.gov/en-US/app/search/search?q=search%2010.10.10.1"
                },
                "type" => "link"
            },
            "geoip" => {
                "data" => {
                    "org" => "rfc1918",
                    "asn" => "rfc1918",
                    "asorg" => "rfc1918",
                    "continent" => "rfc1918",
                    "latitude" => "31.030488",
                    "country" => "rfc1918",
                    "isp" => "rfc1918",
                    "city" => "rfc1918",
                    "isocode" => "rfc1918",
                    "longitude" => "-75.275650"
                },
                "type" => "data"
            },
            "blocklist3" => {
                "type" => "data",
                "data" => {
                    "watch" => 0,
                    "blackhole" => 0,
                    "proxy_block" => 0,
                    "firewall" => 0,
                    "whitelist" => 0
                }
            },
            "ick_ip" => {
                "type" => "link",
                "data" => {
                    "url" => "https://ick.sandia.gov/ipaddress/details/10.10.10.1",
                    "title" => "ICK IP Details"
                }
            },
            "robtex_ip" => {
                "type" => "link",
                "data" => {
                    "url" => "https://www.robtex.com/ip/10.10.10.1.html",
                    "title" => "Lookup on Robtex (external)"
                }
            }
        },
        "location" => "snl"
    })->status_is(200);

$t->post_ok('/scot/api/v2/link' => json => {
    vertices    => [
        { id => 1, type => "entity" },
        { id => 1, type => "event" }
    ],
    memo => [ "10.10.10.1", "foobar" ],
    when => time(),
    weight => 1,
})->status_is(200);

$t  ->post_ok  ('/scot/api/v2/browser'  => json => {
        command => 'flair',
        html    => '<html><head><title>Foo</title></head><body><h1>Foobar Strikes</h1><p>yet again from 10.10.10.1</p></body></html>',
        uri     => 'https://cool.com/foobar.html',
    })
    ->status_is(202);

my $rfid = $t->tx->res->json->{rfid};

ok(defined $rfid, "Received a rfid!");

my $done = 0;
my @valid_status    = (qw(requested processing ready));
while ( ! $done ) {

    $t  ->get_ok("/scot/api/v2/remoteflair/$rfid")
        ->status_is(200);

    print Dumper($t->tx->res->json), "\n";
    my $status  = $t->tx->res->json->{status};
    ok(grep {/$status/} @valid_status, "Valid status $status received");

    if ( $status eq "ready" ) {
        $done = 1;
    }
    sleep 1;
}

 print Dumper($t->tx->res->json), "\n";
 done_testing();
 exit 0;



