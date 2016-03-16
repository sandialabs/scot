#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use lib '../../lib';
use v5.18;
use Scot::Env;
use Scot::App::Flair;


my $env     = Scot::Env->new({
    logfile     => '/var/log/scot/flair.log',
    authtype    => 'Remoteuser',
    servername  => 'as3001snllx',
});
my $loop    = Scot::App::Flair->new({ env => $env });
$loop->run();

