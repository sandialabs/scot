#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(signatures say);
no warnings qw(experimental::signatures);

foo("hello");

sub foo ($bar) {
    say $bar;
}
