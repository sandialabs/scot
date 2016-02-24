#!/usr/bin/env perl

use lib '../lib';
use Scot::Env;
use Scot::Util::Messageq;

my $env = Scot::Env->new();
my $mq  = Scot::Util::Messageq->new();

my $href    = {
    action  => "create",
    type    => "alertgroup",
    data    => {
        arb => [ qw(one two) ],
        foo => "bar",
    },
    id      => 1,
};

$mq->send("scot", $href);
