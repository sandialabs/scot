#!/usr/bin/env perl

use lib '../lib';
use v5.16;

use strict;
use warnings;

use Net::Stomp;
use Scot::Env;
use JSON;
use Data::Dumper;
use DateTime;

my $stomp   = Net::Stomp->new({
    hostname    => 'localhost',
    port        => 61613,
    ack         => 'client',
});

$stomp->connect();
$stomp->subscribe({
    destination => '/topic/scot',
    ack         => 'client',
    'activemq.prefetchSize' => 1,
});


while (1) {
    say "waiting...";
    my $frame   = $stomp->receive_frame;
    say "------------------- FRAME START ------------------";
    my $headers = $frame->headers;
    my $body    = $frame->body;
    my $json    = decode_json($body);

    say Dumper($headers);
    say Dumper($json);

    $stomp->ack({frame => $frame});
    say "------------------- FRAME END   ------------------";
}

