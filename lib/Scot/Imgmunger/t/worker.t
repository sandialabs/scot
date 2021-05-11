#!/usr/bin/env perl

use strict;
use warnings;
use lib '../../../../lib';
use lib '.';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use HTML::Element;
use feature qw(say);

my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new({config_file => $config_file});
my $timer       = $env->get_timer("All Test Completed");

ok (defined $env, "Environment defined");
ok (ref($env) eq "Scot::Env", "It is a Scot::Env");

require_ok('Scot::Imgmunger::Worker');
my $worker = Scot::Imgmunger::Worker->new({env => $env});
ok (defined $worker, "worker module instantiated");
is (ref($worker), "Scot::Imgmunger::Worker", "and it is a worker");

my $stomp = $worker->stomp;
is (ref($stomp), 'Net::Stomp', "instantiated a Net::Stomp object");

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
    { action => 'created', data => { type => 'entry', id => 1 }},
    { action => 'updated', data => { type => 'entry', id => 1 }},
);

foreach my $href (@valid_data) {
    ok (!$worker->invalid_data($href), "Valid data detected sucessfully");
}


done_testing();
