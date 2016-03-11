#!/usr/bin/env perl
use Mojo::Server::Hypnotoad;

my $hypno = Mojo::Server::Hypnotoad->new(
    workers => 10,
    proxy   => 1,
    pid_file => '/var/run/hypnoscot.pid',
    listen  => [ 'http://localhost:5000' ],
    clients => 1,
    accepts => 2,
);

$hypno->run('/opt/scot/script/Scot');
