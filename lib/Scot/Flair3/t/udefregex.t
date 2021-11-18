#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Log::Log4perl;
use Meerkat;



my $iopackage   = "Scot::Flair3::Io";
require_ok($iopackage);
my $io  = Scot::Flair3::Io->new(
    log     => $log,
    mongo   => $mongo,
    queue   => $queue,
    topic   => $topic,
);
ok(defined $io, "io initialized");

my $package = "Scot::Flair3::UdefRegex";
require_ok($package);
my $r = Scot::Flair3::UdefRegex->new(io => $io);

my $set = $r->regex_set;

print Dumper($set);
