#!/usr/bin/env perl

use strict;
use warnings;
use lib '/opt/scot/lib';
use lib '../lib';
use lib '../../lib';
use lib '../../Scot-Internal-Modules/lib';
use v5.18;
use Scot::App::Flair;
use Data::Dumper;


# SAMPLE code on how to reprocess all flair

my $loop    = Scot::App::Flair->new( 
    configuration_file  => '/home/tbruner/flair.app.cfg',
    interactive  => 1,
);
my $json = $loop->reprocess();
say Dumper($json);

