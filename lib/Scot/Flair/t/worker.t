#!/usr/bin/env perl

use strict;
use warnings;
use lib '../../../../lib';
use lib '.';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use TestSamples;
use HTML::Element;
use feature qw(say);

my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new({config_file => $config_file});
my $timer       = $env->get_timer("All Test Completed");

ok (defined $env, "Environment defined");
ok (ref($env) eq "Scot::Env", "It is a Scot::Env");

require_ok('Scot::Flair::Worker');
my $worker = Scot::Flair::Worker->new({env => $env});
ok (defined $worker, "worker module instantiated");
is (ref($worker), "Scot::Flair::Worker", "and it is a worker");

my $stomp = $worker->stomp;
is (ref($stomp), 'Net::Stomp', "instantiated a Net::Stomp object");

my $regex = $worker->regexes;
is (ref($regex), 'Scot::Flair::Regex', "instantiated a Regex object");

my $io = $worker->io;
is (ref($io), 'Scot::Flair::Io', "instantiated a Io object");

my $extractor = $worker->extractor;
is (ref($extractor), 'Scot::Flair::Extractor', "instantiated a Extractor object");

my @invalid_data = (
    # missing action:
    { data => "foobar" },
    # invalid action:
    { action => 'messitup', data => 'foobar' },
    # invalid data: bad type
    { action => 'created',  data => { type => 'boombaz', id => 1 }},
    # invalid data: bad id
    { action => 'updated',  data => { type => 'entry', id => 'x' }},
);

foreach my $href (@invalid_data) {
    ok ($worker->invalid_data($href), "Invalid data detected sucessfully");
}

my @valid_data = (
    { action => 'created', data => { type => 'alertgroup', id => 1}},
    { action => 'updated', data => { type => 'alertgroup', id => 1}},
    { action => 'created', data => { type => 'entry', id => 1 }},
    { action => 'updated', data => { type => 'entry', id => 1 }},
    { action => 'created', data => { type => 'remoteflair', id => 1}},
    { action => 'updated', data => { type => 'remoteflair', id => 1}},
);

foreach my $href (@valid_data) {
    ok (!$worker->invalid_data($href), "Valid data detected sucessfully");
    my $proc = $worker->get_processor($href);
    ok (defined $proc, "Got a processor");
    my $expected = "Scot::Flair::Processor::".ucfirst($href->{data}->{type});
    is (ref($proc), $expected, "Got the right type");
}


done_testing();
