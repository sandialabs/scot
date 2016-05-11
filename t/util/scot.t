#!/usr/bin/env perl

use warnings;
use strict;
use v5.18;
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Scot::Env;
use Scot::Util::Scot;
use Data::Dumper;

$ENV{'scot_mode'}       = "testing";
$ENV{'SCOT_AUTH_TYPE'}  = "Testing";

my $env     = Scot::Env->new();
my $scot    = Scot::Util::Scot->new({
    env         => $env,
    servername  => 'as3001snllx.sandia.gov:3000',
    username    => 'scot-alerts',
    password    => 'ukeSb=r9',
});

my $json    = $scot->get('config','2');
say Dumper($json);

my $tx  = $scot->post({
    message_id  => '112233445566778899aabbccddeeff',
    subject     => 'test message 1',
    data        => [
        { foo   => 1,   bar => 2 },
        { foo   => 3,   bar => 4 },
    ],
    tags     => [qw(test testing)],
    sources  => [qw(todd scot)],
    columns  => [qw(foo bar) ],
});

my $alertgroup_id   = $tx->res->json->{id};

my $txget   = $scot->get_url(
    "/scot/api/v2/alertgroup/$alertgroup_id"
);

say Dumper($txget->res->json);

my $atxget  = $scot->get_url(
    "/scot/api/v2/alertgroup/$alertgroup_id/alert"
);

say Dumper($atxget->res->json);
