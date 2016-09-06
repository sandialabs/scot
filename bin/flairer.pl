#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use lib '../../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
use v5.18;
use Scot::App::Flair2;


my $loop    = Scot::App::Flair2->new( 
    configuration_file  => 'flair.app.cfg',
    interactive  => 1,
);
$loop->run();

