#!/usr/bin/env perl

use lib '../../lib';
use v5.18;

use strict;
use warnings;

use AnyEvent::STOMP::Client;
use Scot::Env;
use JSON;
use Data::Dumper;
use DateTime;

my $stomp   = AnyEvent::STOMP::Client->new();

$stomp->connect();
$stomp->on_connected(
    sub { 
        my $stomp   = shift;
        $stomp->subscribe('/topic/scot','auto',
#            {'activemq.prefetchSize' => 0},
        );
    }
);

my %received_ids    = ();

$stomp->on_message(
    sub {
        my ( $stomp, $header, $body ) = @_;

        my $json = decode_json $body;
        my $id   = $json->{data}->{id};
        say "Received Message id: $id";
        $received_ids{$id}++;

        $id += 0;
        if ($id eq -1) {
            for (my $i = 1; $i < 10; $i++) {
                unless ( $received_ids{$i} ) {
                    say "ERROR: Missed message $i";
                }
            }
        }
    }
);

$stomp->on_disconnected(
    sub {
        my ( $stomp, $host, $port) = @_;

    }
);



say "===== Testing ActiveMQ =========";
AnyEvent->condvar->recv;



