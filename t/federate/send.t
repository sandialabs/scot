#!/usr/bin/env perl
use JSON;
use Net::STOMP::Client;
use Data::Dumper;

my $host    = "localhost";
my $port    = 61613;
my $stomp   = Net::STOMP::Client->new( host => $host, port => $port );
my $queue   = '/queue/as3015snllx-upstream';

$stomp->connect( login => "scot", passcode => "scot1234");

my $object  = encode_json({
    key1    => "test",
    key2    => "foo",
});

print "Sending ".Dumper($object);

$stomp->send(
    destination => $queue,
    body => $object,
);

$stomp->disconnect;
