#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use lib '../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
use Scot::App::Mail;
use Scot::Env;
use Data::Dumper;

# sample code on how to reprocess an alertgroup for flair
# ./reprocess_alertgroup.pl 123


say "--- Starting Mail Reprocessor ---";

my $processor   = Scot::App::Mail->new({
    configuration_file         => "mail.app.cfg",
    interactive                 => "no",
});

my $id = $ARGV[0];
$processor->reprocess_alertgroup($id);
