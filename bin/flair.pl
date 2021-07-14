#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use lib '../../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
use Scot::Flair::Worker;
use Data::Dumper;
use utf8::all;
use feature qw(say);

my $config_file = $ENV{'scot_app_flair_config_file'} //
                        '/opt/scot/etc/flair.cfg.pl';
my $env = Scot::Env->new(
    config_file => $config_file,
);

die unless defined $env and ref($env) eq "Scot::Env";

$SIG{__DIE__} = sub { our @reason = @_ };

END {
    our @reason;
    if (@reason) {
        say "Flairer died because: @reason";
        $env->log->error("Flairer died because: ",{filter=>\&Dumper, value=>\@reason});
    }
}

# say Dumper($env);

my $loop    = Scot::Flair::Worker->new(env => $env);
$loop->run();

