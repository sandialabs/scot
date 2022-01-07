#!/usr/bin/env perl

use strict;
use warnings;
use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use feature qw(say);

require_ok("Scot::Flair3::Stomp");

my $s   = Scot::Flair3::Stomp->new();

is (ref($s), "Scot::Flair3::Stomp", "Initialized");

my $sender      = $s->sender;
my $receiver    = $s->receiver;

is (ref($sender),   "Net::Stomp", "sender initialized");
is (ref($receiver), "Net::Stomp", "receiver(s) initialized");

my $q   = "/queue/test";
my $t   = "/topic/test";

$s->subscribe($q);
$s->subscribe($t);

my $msg1   = {
    action  => 'test',
    data    => {
        foo     => 'bar',
        boom    => 'baz',
    }
};

$s->send($q, $msg1);
$s->send($q, $msg1);

my $frame   = $s->receive();
say Dumper($frame);

$frame   = $s->receive();
say Dumper($frame);

