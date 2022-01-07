#!/usr/bin/env perl

use Net::Stomp;
use Data::Dumper;
use Data::GUID;
use JSON;

my $s = Net::Stomp->new({
    hostname    => 'localhost',
    port        => 61613,
    ack         => 'client',
});

$s->connect();
my $msg = { foo => 'bar', pid => $$ };
my $body = encode_json($msg);
my $len  = length($body);
my $guid = Data::GUID->new;
my $gstr = $guid->as_string;
my $frame   = {
    destination => '/queue/flairtest',
    body        => $body,
    'content-length'    => $len,
    'amq-msg-type'      => 'text',
    persistent          => 'true',
};
my $rcf;
 
$s->send_transactional($frame, $rcf);

$s->subscribe({
    destination             => '/queue/flairtest',
    ack                     => 'client',
    'activemq.prefetchSize' => 1,
});

my $frame = $s->receive_frame;

print "Recv frame ".Dumper($frame);
print "NACK...\n";
$s->nack({frame => $frame});

sleep 10;

print "ACK...\n";
$s->ack({frame => $frame});


