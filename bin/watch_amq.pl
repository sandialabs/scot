#!/usr/bin/env perl

use lib '../lib';
use v5.18;

use strict;
use warnings;

use AnyEvent::STOMP::Client;
use Scot::Env;
use JSON;
use Data::Dumper;

my $stomp   = AnyEvent::STOMP::Client->new();

$stomp->connect();
$stomp->on_connected(
    sub { 
        my $stomp   = shift;
        $stomp->subscribe('/scot');

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



