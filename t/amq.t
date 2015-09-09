#!/usr/bin/env perl

use lib '../lib';
use lib '../../lib';

use Test::More;
use Data::Dumper;
use Scot::Env;

$ENV{'scot_mode'} = "testing";
my $env = Scot::Env->new({});

my $amq = $env->amq;

# ok(defined($amq), "Got ActiveMQ helper module");
# is(ref($amq->stomp_handle), "Net::STOMP::Client", "Got the STOMP handle");

$amq->stomp_handle->message_callback(sub {
    my $self    = shift;
    my $frame   = shift;
    $self->ack( frame => $frame );
    printf("Received: %s\n", $frame->body());
    return ($self);
});

$amq->stomp_handle->subscribe(
    destination => "/topic/alert", 
    id          => "alert_queue",
    ack         => "client",
);

$amq->stomp_handle->send(
    destination => "/topic/alert",
    body        => "hello world",
);

# done_testing();
