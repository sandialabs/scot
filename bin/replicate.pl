#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use lib '../../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
use v5.18;
use Scot::App::Replicate;


my $loop    = Scot::App::Replicate->new( 
    configuration_file  => 'replicate.app.cfg',
    interactive  => 1,
);
$loop->run();

