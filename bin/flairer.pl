#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use v5.18;
use Scot::Env;
use Scot::Controller::Flair;

$ENV{scot_mode} = "testing";

my $env     = Scot::Env->new({
    mongo_config    =>  {
        host    => 'mongodb://localhost',
        db_name  => 'scot-testing',
        find_master => 1,
        write_safety => 1,
        port        => 27017,
        user    => 'scot',
        pass    => 'scot',

    },
});
my $loop    = Scot::Controller::Flair->new({ env => $env });
$loop->run();

