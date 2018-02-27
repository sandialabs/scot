#!/usr/bin/env perl

use lib '../lib';
use v5.18;

use Scot::Util::HttpStomp;
use Scot::Env;
use Data::Dumper;

my $config_file = "/opt/scot/etc/scotdemostomp.cfg.pl";
my $env         = Scot::Env->new(config_file => $config_file);

my $hstomp = Scot::Util::HttpStomp->new(
    env => $env,
);

$hstomp->get(sub {
    my ($ua, $tx) = @_;
    say "------------------------------------";
    say Dumper($tx->result->body);
    say "------------------------------------";
});


