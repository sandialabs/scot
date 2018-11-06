#!/usr/bin/env perl
use lib '../lib';
use Data::Dumper;
use JSON;
use Net::STOMP::Client;
use v5.16;

my $stomp = Net::STOMP::Client->new(
    host    => '127.0.0.1',
    port    => 61613,
);
$stomp->connect(login => "scot", passcode => "scot1234");

for my $i (1..10) {

    my $href    = {
        id      => $i,
        type    => "foo",
        data    => {
            key1    => "value1",
            key2    => "value2",
            key3    => "value3",
            key4    => "value4",
        }
    };

    my $json = encode_json $href;
    $stomp->send(
        destination => "/queue/incoming",
        body        => $json,
    );

    sleep 1;
}

$stomp->disconnect;
