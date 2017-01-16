#!/usr/bin/env perl

use lib '../lib';
use lib '../../lib';

#use Test::More;
use Data::Dumper;
use JSON;
use Net::STOMP::Client;

$ENV{'scot_mode'} = "testing";

my $stomp = Net::STOMP::Client->new(
    host    => "127.0.0.1",
    port    => 61613
);
$stomp->connect();


    my $href    = {
            id          => 192,
            type        => "alert",
            user        => "foobar",
        };

    my $json    = encode_json $href;

    $stomp->send(
        destination => "/topic/alert",
        body        => $json,
    );

$stomp->disconnect();
