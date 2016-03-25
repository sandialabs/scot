#!/usr/bin/env perl

use lib '../../lib';
use v5.18;
use strict;
use warnings;

use Scot::Env;
use Scot::Util::Messageq;

my $env = Scot::Env->new({
    logfile => '/var/log/scot/stomptest.log',
});

my $mq  = Scot::Util::Messageq->new({
    env => $env,
});

# send a hundred messages

for (my $i = 1; $i < 100; $i++) {

    $mq->send("scot", {
        action  => 'created',
        data    => {
            type    => 'alert',
            id      => $i,
            who     => 'foobar',
        }
    });
    
}
$mq->send("scot", {
    "action"    => 'stop',
    data        => { id => -1},
});
