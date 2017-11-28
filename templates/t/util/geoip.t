#!/usr/bin/env perl

use warnings;
use strict;
use v5.18;
use lib '../../lib';

use Test::More;
use Scot::Env;
use Scot::Util::Geoip;
use Data::Dumper;
my %data;

my $env     = Scot::Env->new();
my $geoip   = Scot::Util::Geoip->new({
    env         => $env,
});

my $ip  = "198.102.153.2"; # a public facing sandia address
my $rec = $geoip->get_scot_geo_record($ip);

is ( $rec->{city}, "Albuquerque", "Correct City Name");
is ( $rec->{isp}, "Sandia National Laboratories", "Correct ISP");
is ( $rec->{timezone}, "America/Denver", "Correct Timezone");
is ( $rec->{asn}, 377, "Correct ASN");
is ( $rec->{asorg}, "Sandia National Laboratories", "Correct AS ORG");
is ( int($rec->{latitude}), 35, "Correct Latitude");
is ( int($rec->{longitude}), -106, "Correct Longitude");
is ( $rec->{continent}, "North America", "Correct Continent");
is ( $rec->{country}, "United States", "Correct country");
is ( $rec->{isocode}, "US", "Correct ISO country code");

my $href    = $geoip->get_data("ipaddr", $ip);
say Dumper($href);

done_testing();
exit 0;
