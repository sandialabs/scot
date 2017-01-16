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

$stomp->message_callback(sub {
    my $self    = shift;
    my $frame   = shift;
    $self->ack( frame => $frame );
    printf("Received: %s\n", $frame->body());
    return ($self);
});

$stomp->subscribe(
    destination => "/topic/alert", 
    id          => "alert_queue",
    ack         => "client",
);
$stomp->subscribe(
    destination => "/topic/entry", 
    id          => "entry_queue",
    ack         => "client",
);

$stomp->wait_for_frames(callback => sub {
    my $self    = shift;
    my $frame   = shift;
    if ( $frame->command eq "MESSAGE" ) {
        return(1) if $frame->body eq "quit";
    }
    printf("RCV: %s\n", $frame->body());
    return (0);
});

print "WAITING!\n";
