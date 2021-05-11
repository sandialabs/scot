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

my $config  = {};

require_ok('Scot::Enricher::Enrichment::Geoip');
my $geo = Scot::Enricher::Enrichment::Geoip->new({config => $config});

my @tests = (
    {
        test    => 'private ip',
        ip      => '192.168.4.4',
        expect  => {
            continent  => 'rfc1918',
            isocode     => 'rfc1918',
            asorg       => 'rfc1918',
            isp         => 'rfc1918',
            latitude    => '31.030488',
            org         => 'rfc1918',
            asn         => 'rfc1918',
            city        => 'rfc1918',
            longitude   => '-75.275650',
            country     => 'rfc1918',
        },
    },
    {
        test    => 'google nameserver',
        ip => '8.8.8.8',
        expect  => {
            continent  => 'North America',
            timezone    => 'America/Chicago',
            isocode     => 'US',
            asorg       => 'GOOGLE',
            isp         => 'Google',
            latitude    => '37.751',
            org         => 'Google',
            asn         => '15169',
            city        => undef,
            longitude   => '-97.822',
            country     => 'United States',
        },
    },
    {
        test    => 'sandia ip',
        ip      => '134.253.14.14',
        expect  => {
          'isp' => 'Sandia National Laboratories',
          'city' => undef,
          'continent' => 'North America',
          'isocode' => 'US',
          'timezone' => 'America/Chicago',
          'asn' => 377,
          'longitude' => '-97.822',
          'asorg' => 'SNLA-NET-AS',
          'country' => 'United States',
          'org' => 'Sandia National Laboratories',
          'latitude' => '37.751'
        },
    },
);

foreach my $test (@tests) {
    my $result = $geo->enrich($test->{ip});
    say Dumper($result);
    cmp_deeply($result, $test->{expect}, "Recieved expected data");
}

done_testing();

