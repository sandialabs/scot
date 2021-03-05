#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use Scot::Env;
use Module::Runtime qw(require_module);

my $class = "Scot::Email::Responder::".ucfirst($ARGV[0]);

require_module($class);

my $config = "/opt/scot/etc/email_".lc($class).".cfg.pl";
my $env    = Scot::Env->new(config => $config);

# move this to config?
my %queue_map = (
    AlertEmailPassThrough   => {
        queue   =>'/queue/email_alertpassthrough',
        workers => 1,
    },
    Alert   => {
        queue   => '/queue/email_alerts',
        workers => 1,
    },
    Event  => {
        queue   => '/queue/email_events',
        workers => 1,
    },
    Dispatch    => {
        queue   => '/queue/email_dispatch',
        workers => 1,
    },
);

my $queue   = $queue_map{$class}->{queue};
my $workers = $queue_map{$class}->{workers};

my $responder = $class->new(env => $env, queue => $queue, max_workers => $workers);

$responder->run();

