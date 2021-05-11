#!/usr/bin/env perl

use lib '../../../../lib';
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use feature qw(say);

my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new(config_file=>$config_file);
require_ok('Scot::Enricher::Io');
my $io = Scot::Enricher::Io->new({env => $env});


require_ok('Scot::Enricher::Processor');
my $proc = Scot::Enricher::Processor->new({env => $env, scotio => $io});

my @tests   = (
    {
        data    => {
            id  => 1,
        },
        config  => {
            name    => 'internal link',
            type    => 'internal_link',
            url     => '/scot/api/v2/foobar/%s',
            field   => "id",
            title   => 'foobar api',
            nopopup => 1,
        },
        expect => {
            'internal link' => {
                type    => 'link',
                data    => {
                    url => '/scot/api/v2/foobar/1',
                    title   => 'foobar api',
                    nopopup => 1,
                },
            },
        },
    },
);

foreach my $test (@tests) {

    my $result  = $proc->enrich($test->{data}, $test->{config});
    say Dumper($result);
    cmp_deeply($result, [$test->{expect}], "Got the correct enrichment");

}


