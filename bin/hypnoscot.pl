#!/usr/bin/env perl
use Mojo::Server::Hypnotoad;
use Data::Dumper;

## this script starts the hypnotoad app server
## the settings in Scot.pm override these settings

my $port    = 5000;
my %params = (
    workers => 10,
    proxy   => 1,
    pid_file => '/var/run/hypnoscot.pid',
    listen  => [ "http://localhost:$port" ],
    clients => 1,
    accepts => 1,
    heartbeat_timeout   => 10,
);

my $hypno = Mojo::Server::Hypnotoad->new(%params);

$hypno->run('/opt/scot/script/Scot');
