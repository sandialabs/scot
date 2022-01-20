#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use lib '../../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
# use Scot::Flair::Worker;
use Scot::Flair::Worker;
use Scot::Env;
use Data::Dumper;
use utf8::all;
use Carp qw(cluck longmess shortmess);
use feature qw(say);

my $env     = Scot::Env->new(config_file => '/opt/scot/etc/flair.cfg.pl');
my $log     = $env->log;

die unless defined $env and ref($env) eq "Scot::Env";

$SIG{__DIE__} = sub { our @reason =@_};

END {
    our @reason;
    if (@reason) {
        say "Flair Diead because: @reason";
        $env->log->error("Flair died because: ", {filter => \&Dumper, value =>\@reason});
    }
}


my $loop    = Scot::Flair::Worker->new(env => $env);
$loop->run();

