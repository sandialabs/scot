#!/usr/bin/env perl

use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use feature qw(say);

my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new({config_file => $config_file});

require_ok('Scot::Flair::Regex');

my $regex = Scot::Flair::Regex->new({env => $env});

ok(defined $regex, "Regex module instantiated");

say Dumper($regex->single_word_regexes);
say Dumper($regex->single_word_regexes);


