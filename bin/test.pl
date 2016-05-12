#!/bin/env perl

use lib '../lib';
use Scot::App::Test;

my $t = Scot::App::Test->new(
    configuration_file  => "/home/tbruner/flair.app.cfg",
);

$t->do_it;
