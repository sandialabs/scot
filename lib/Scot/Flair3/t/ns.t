#!/usr/bin/env perl

use Net::Stomp;
use Data::Dumper;

my $s = Net::Stomp->new({
    hostname    => 'localhost',
    port        => 61613,
    ack         => 'client',
});

$s->connect();

my $t   = Net::Stomp->new({
    hostname    => 'localhost',
    port        => 61613,
    ack         => 'client',
});

$t->connect();

$s->subscribe({
    destination => '/queue/foo',
    ack         => 'client',
    'activemq.prefetchSize' => 1,
});
$s->subscribe({
    destination => '/topic/foo',
    ack         => 'client',
    'activemq.prefetchSize' => 1,
});

my $body    = '{"foo":"bar", "pid":'.$$.'}';
my $rv;
my $success = $t->send_transactional({
    destination => '/queue/foo',
    body        => $body,
    'content-length'    => length($body),
    'amq-msg-type'      => 'text',
    persistent          => 'true',
}, $rv);

if (! $success ) {
    warn $rv->as_string;
}

my $frame   = $s->receive_frame;

warn Dumper($frame);
$s->ack({frame => $frame});

$success = $t->send_transactional({
    destination => '/topic/foo',
    body        => $body,
    'content-length'    => length($body),
    'amq-msg-type'      => 'text',
    persistent          => 'true',
}, $rv);

if (! $success ) {
    warn $rv->as_string;
}

$frame   = $s->receive_frame;

warn Dumper($frame);
$s->ack({frame => $frame});
