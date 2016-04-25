package Scot::Util::Geoip;

use lib '../../../lib';
use lib '../lib';
use strict;
use warnings;
use v5.18;

use Data::Dumper;
use GeoIP2::Database::Reader;
use namespace::autoclean;

use Moose;

has env         => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
    default     => sub { Scot::Env->instance; },
);

has citydb      => (
    is          => 'ro',
    isa         => 'GeoIP2::Database::Reader',
    lazy        => 1,
    required    => 1,
    builder     => '_get_city_reader',
);

sub _get_city_reader {
    my $self    = shift;
    my $dbfile  = "/usr/share/GeoIP/GeoIP2-City.mmdb";
    my $locales = ["en"];

    return GeoIP2::Database::Reader->new(
        file    => $dbfile,
        locales => $locales,
    );
}

has countrydb      => (
    is          => 'ro',
    isa         => 'GeoIP2::Database::Reader',
    lazy        => 1,
    required    => 1,
    builder     => '_get_country_reader',
);

sub _get_country_reader {
    my $self    = shift;
    my $dbfile  = "/usr/share/GeoIP/GeoIP2-Country.mmdb";
    my $locales = ["en"];

    return GeoIP2::Database::Reader->new(
        file    => $dbfile,
        locales => $locales,
    );
}

has ispdb      => (
    is          => 'ro',
    isa         => 'GeoIP2::Database::Reader',
    lazy        => 1,
    required    => 1,
    builder     => '_get_isp_reader',
);

sub _get_isp_reader {
    my $self    = shift;
    my $dbfile  = "/usr/share/GeoIP/GeoIP2-ISP.mmdb";
    my $locales = ["en"];

    return GeoIP2::Database::Reader->new(
        file    => $dbfile,
        locales => $locales,
    );
}

sub get_city_data {
    my $self    = shift;
    my $ip      = shift;

    return $self->citydb->city( ip => $ip );
}

sub get_country_data {
    my $self    = shift;
    my $ip      = shift;

    return $self->countrydb->country( ip => $ip );
}

sub get_isp_data {
    my $self    = shift;
    my $ip      = shift;

    return $self->ispdb->isp( ip => $ip );
}

sub get_scot_geo_record {
    my $self    = shift;
    my $ip      = shift;
    my $city    = $self->get_city_data($ip);
    my $isp     = $self->get_isp_data($ip);

    my %data    = (
        city        => $city->city->name,
        country     => $city->country->name,
        isocode     => $city->country->iso_code,
        continent   => $city->continent->name,
        latitude    => $city->location->latitude,
        longitude   => $city->location->longitude,
        timezone    => $city->location->time_zone,
        asorg       => $isp->autonomous_system_organization,
        asn         => $isp->autonomous_system_number,
        isp         => $isp->isp,
        org         => $isp->organization,
    );
    return wantarray ? %data : \%data;
}

# necessary for entity_enrichers
sub get_data {
    my $self    = shift;
    my $type    = shift;
    my $value   = shift;

    if ($type ne "ipaddr") {
        # nothing to do here...
        return {};
    }

    my $href    = $self->get_scot_geo_record($value);
    return $href;
}



1;
