#!/usr/bin/env perl

use lib '../lib';
use lib '../../lib';

#use Test::More;
use Data::Dumper;
use Net::STOMP::Client;

$ENV{'scot_mode'} = "testing";

my $stomp = Net::STOMP::Client->new(
    host    => "127.0.0.1",
    port    => 61613
);
$stomp->connect();

for (my $i = 1; $i < 10; $i++) {

    $stomp->send(
        destination => "/topic/alert",
        body        => "Message # $i",
    );

}
$stomp->send(
    destination => "/topic/alert",
    body        => "quit",
);
$stomp->disconnect();
