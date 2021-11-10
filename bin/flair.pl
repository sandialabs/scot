#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use lib '../../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
# use Scot::Flair::Worker;
use Scot::Flair3::Worker;
use Data::Dumper;
use utf8::all;
use Carp qw(cluck longmess shortmess);
use feature qw(say);

my $config_file = $ENV{'scot_app_flair_config_file'} //
                        '/opt/scot/etc/flair.cfg.pl';
my $env = Scot::Env->new(
    config_file => $config_file,
);

die unless defined $env and ref($env) eq "Scot::Env";

$SIG{'__WARN__'} = sub {
    do {
        $Log::Log4perl::caller_depth++;
        no warnings 'uninitialized';
        $env->log->warn(@_);
        unless ( grep { /uninitialized/ } @_ ) {
            $env->log->warn(longmess());
        }
        $Log::Log4perl::caller_depth--;
    }
};

$SIG{'__DIE__'} = sub {
    if ( $^S ) {
        return;
    }
    $Log::Log4perl::caller_depth++;
    $env->log->fatal(@_);
    die @_;
};


# $SIG{__DIE__} = sub { our @reason = @_ };
#END {
#    our @reason;
#    if (@reason) {
#        say "Flairer died because: @reason";
#        $env->log->error("Flairer died because: ",{filter=>\&Dumper, value=>\@reason});
#    }
#}

# say Dumper($env);

$env->log->info("------");
$env->log->info("------ core flair daemon starts");
$env->log->info("------");

# my $loop    = Scot::Flair::Worker->new(env => $env);
my $loop    = Scot::Flair3::Worker->new();
$loop->run();

