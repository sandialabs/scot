#!/usr/bin/env perl

use lib '../lib';
use v5.18;

use strict;
use warnings;

use AnyEvent::STOMP::Client;
use Scot::Env;
use JSON;
use Data::Dumper;
use DateTime;


my $stomp   = AnyEvent::STOMP::Client->new("localhost", 61613, {login=>"scot", passcode=>"scot1234"});

$stomp->connect();
$stomp->on_connected(
    sub { 
        my $stomp   = shift;
        $stomp->subscribe('/queue/coe');
    }
);

$stomp->on_error(
    sub {
        say "ERROR";
        say Dumper(\@_);
    }
);

$stomp->on_message(
    sub {
        my ( $stomp, $header, $body ) = @_;

        my $json = decode_json $body;

        my $dt  = DateTime->now();
       
        my $date    = $dt->ymd . " ". $dt->hms;
        my $dl  = length($date);

        my $nd = 80 - $dl - 10;

        say "-"x10 . $dt->ymd . " ". $dt->hms. "-"x$nd;
        say Dumper($json);
        say "-"x80;
    }
);
say "===== Watching ActiveMQ =========";
AnyEvent->condvar->recv;



