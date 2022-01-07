#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);
use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;

require_ok("Scot::Flair3::Worker");

my $worker  = Scot::Flair3::Worker->new(
    workers => 1,
    queue   => '/queue/flairtest',
    topic   => '/topic/flairtest',
);

my $ovr = sub {
    my $m   = shift;
    say "Message Decoded to ".Dumper($m);
};


$worker->run($ovr);

