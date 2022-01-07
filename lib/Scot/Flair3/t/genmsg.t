#!/usr/bin/env perl

use strict;
use warnings;
use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use feature qw(say);
use Scot::Flair3::Stomp;
my $s   = Scot::Flair3::Stomp->new();
my $q   = "/queue/flairtest";
my $t   = "/topic/flairtest";
$s->subscribe($q);
my $msg1   = {
    action  => 'test',
    data    => {
        id      => 1,
        type    => 'entry',
        foo     => 'bar1',
        boom    => 'baz',
    }
};
my $msg2   = {
    action  => 'test',
    data    => {
        id      => 2,
        type    => 'entry',
        foo     => 'bar2',
        boom    => 'baz',
    }
};
my $msg3   = {
    action  => 'test',
    data    => {
        id      => 3,
        type    => 'entry',
        foo     => 'bar3',
        boom    => 'baz',
    }
};

say "Sending Message to Queue...";
$s->send($q, $msg1);
#say "Sending Message to Queue...";
#$s->send($q, $msg2);
#say "Topic Message to Queue...";
#$s->send($t, $msg3);


