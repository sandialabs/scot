#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use lib '../../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
# use Scot::Flair::Worker;
use Scot::Flair3::Worker;
use Scot::Env;
use Data::Dumper;
use utf8::all;
use Carp qw(cluck longmess shortmess);
use feature qw(say);

my $loop    = Scot::Flair3::Worker->new();
my $log     = $loop->engine->log;
# not used but painted myself into a corner
# meerkat models and collections reference env
my $env = Scot::Env->new(config_file => '/opt/scot/etc/flair.cfg.pl');
$SIG{'__WARN__'} = sub {
    do {
        $Log::Log4perl::caller_depth++;
        no warnings 'uninitialized';
        print warn(@_)."\n";
        unless ( grep { /uninitialized/ } @_ ) {
            $log->warn(longmess());
        }
        $Log::Log4perl::caller_depth--;
    }
};

$SIG{'__DIE__'} = sub {
    if ( $^S ) {
        return;
    }
    $Log::Log4perl::caller_depth++;
    $log->logdie( @_);
};



$loop->run();

