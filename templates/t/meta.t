#!/usr/bin/env perl

use warnings;
use strict;
use v5.18;
use lib '../lib';
use Data::Dumper;
use Test::More;
use Moose;
use Module::Runtime qw(require_module);

my $class = 'Scot::Model::Guide';

require_module($class);

my $meta = Moose::Meta::Class->initialize('Scot::Model::Guide');

if ( $meta->does_role('Scot::Role::Entriable') ) {
    say "it does it!";
}
say "done";

