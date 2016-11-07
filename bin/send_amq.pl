#!/usr/bin/env perl

use lib '../lib';
use v5.18;

use strict;
use warnings;

# sample code on how to watch for topic messages

use AnyEvent::STOMP::Client;
use Scot::Env;
use JSON;

my $stomp   = AnyEvent::STOMP::Client->new();

$stomp->connect();
$stomp->on_connected(
    sub { 
        my $stomp   = shift;
        $stomp->subscribe('/topic/alertgroup');
        $stomp->subscribe('/topic/alert');
        $stomp->subscribe('/topic/event');
        $stomp->subscribe('/topic/entry');
        $stomp->subscribe('/topic/intel');
        $stomp->subscribe('/topic/incident');

    }
);

$stomp->on_message(
    sub {
        my ( $stomp, $header, $body ) = @_;

        my $json = decode_json $body;

        say "-"x80;
        say Dumper($json);
        say "-"x80;
    }
);
say "===== Watching ActiveMQ =========";
AnyEvent->condvar->recv;



