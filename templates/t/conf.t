#!/usr/bin/env perl
use lib '../lib';
use Log::Log4perl;
use Data::Dumper;
use File::Slurp;
use Test::More;

# conf

BEGIN {
    use_ok('Config::Auto');
};
my  $config = "../scot.conf";

my $conf    = Config::Auto::parse($config, format => 'perl');
my $mode    = $conf->{mode};

# print Dumper($conf)."\n";

ok          (defined $conf, "read config file");
is          ( $conf->{mode},    "development",  "in test mode");
is_deeply   ( $conf->{$mode}->{test_groups}, 
                [ qw(ir share test) ], "correct testing groups");

done_testing();


