package Scot::Util::Geoip;

use lib '../../../lib';
use lib '../lib';
use strict;
use warnings;
# use v5.18;

use Data::Dumper;
use GeoIP2::Database::Reader;
use namespace::autoclean;
use Try::Tiny;

use Moose;

has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
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
    my $log     = $self->log;
    my $city;
    my $href    = {};

    $log->debug("attempint city data grab");

    try {
        $city   = $self->citydb->city(ip=>$ip);
        $href   = {
            city        => $city->city->name,
            country     => $city->country->name,
            isocode     => $city->country->iso_code,
            continent   => $city->continent->name,
            latitude    => $city->location->latitude,
            longitude   => $city->location->longitude,
            timezone    => $city->location->time_zone,
        };
    }
    catch {
        $log->error(
            sprintf("GEOIP error: %s", 
                     $_->message));
        if ( $_->message =~ /not a public IP/ ) {
            $href   = {
                city    => 'rfc1918',
                country => 'rfc1918',
                isocode => 'rfc1918',
                continent => 'rfc1918',
                latitude  => '31.030488',
                longitude => '-75.275650',
            };
            return $href;
        }
    };
    return $href;
}

sub get_country_data {
    my $self    = shift;
    my $ip      = shift;
    my $log     = $self->log;
    my $href    = {};

    return $self->countrydb->country( ip => $ip );
}

sub get_isp_data {
    my $self    = shift;
    my $ip      = shift;
    my $log     = $self->log;
    my $href    = {};
    my $isp;

    try {
        $isp    = $self->ispdb->isp(ip=>$ip);
        $href   = {
            asorg       => $isp->autonomous_system_organization,
            asn         => $isp->autonomous_system_number,
            isp         => $isp->isp,
            org         => $isp->organization,
        };
    }
    catch {
        my $message = $_->message;
        $log->error(
            sprintf("GEOIP error: %s ",
                    $message));
        if ( $message =~ /not a public IP/ ) {
            $log->error("non routable ip!");
            $href   = {
                asorg   => 'rfc1918',
                asn     => 'rfc1918',
                isp     => 'rfc1918',
                org     => 'rfc1918',
            };
            return $href;
        }
    };
    return $href;
}

sub get_scot_geo_record {
    my $self    = shift;
    my $ip      = shift;
    my $city    = $self->get_city_data($ip);
    my $isp     = $self->get_isp_data($ip);
    my $log     = $self->log;

    $log->debug("city is ",{filter=>\&Dumper, value=>$city});
    $log->debug("isp  is ",{filter=>\&Dumper, value=>$isp});

    my %data    = (%$city, %$isp);

    $log->debug("scot geo is : ",{filter=>\&Dumper, value=>\%data});

    return wantarray ? %data : \%data;
}

# necessary for entity_enrichers
sub get_data {
    my $self    = shift;
    my $type    = shift;
    my $value   = shift;

    $self->log->debug("getting data for $type $value");

    if ($type ne "ipaddr") {
        # nothing to do here...
        return undef;
    }

    my $href    = $self->get_scot_geo_record($value);
    return $href;
}



1;
