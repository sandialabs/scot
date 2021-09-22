package Scot::Enricher::Enrichment::Geoip;

use GeoIP2::Database::Reader;
use namespace::autoclean;
use Try::Tiny;
use Data::Dumper;

use Moose;
extends 'Scot::Enricher::Enrichment';

has citydb => (
    is          => 'ro',
    isa         => 'GeoIP2::Database::Reader',
    lazy        => 1,
    required    => 1,
    builder     => '_build_citydb',
);

sub _build_citydb {
    my $self    = shift;
    my $dbfile  = '/usr/share/GeoIP/GeoIP2-City.mmdb';
    my $locales = ['en'];

    return GeoIP2::Database::Reader->new(
        file    => $dbfile,
        locales => $locales,
    );
}

has countrydb => (
    is          => 'ro',
    isa         => 'GeoIP2::Database::Reader',
    lazy        => 1,
    required    => 1,
    builder     => '_build_citydb',
);

sub _build_countrydb {
    my $self    = shift;
    my $dbfile  = '/usr/share/GeoIP/GeoIP2-Country.mmdb';
    my $locales = ['en'];

    return GeoIP2::Database::Reader->new(
        file    => $dbfile,
        locales => $locales,
    );
}

has ispdb => (
    is          => 'ro',
    isa         => 'GeoIP2::Database::Reader',
    lazy        => 1,
    required    => 1,
    builder     => '_build_ispdb',
);

sub _build_ispdb {
    my $self    = shift;
    my $dbfile  = '/usr/share/GeoIP/GeoIP2-ISP.mmdb';
    my $locales = ['en'];

    return GeoIP2::Database::Reader->new(
        file    => $dbfile,
        locales => $locales,
    );
}

has anondb => (
    is          => 'ro',
    isa         => 'GeoIP2::Database::Reader',
    lazy        => 1,
    required    => 1,
    builder     => '_build_anondb',
);

sub _build_anondb {
    my $self    = shift;
    my $dbfile  = '/usr/share/GeoIP/GeoIP2-Anonymous.mmdb';
    my $locales = ['en'];

    return GeoIP2::Database::Reader->new(
        file    => $dbfile,
        locales => $locales,
    );
}

sub enrich {
    my $self    = shift;
    my $entity  = shift;
    my $ipaddr  = $entity->value;
    my $log     = $self->env->log;
    # $log->debug("GEOIP ENRICH ",{filter=>\&Dumper, value=> $ipaddr});
    my $city    = $self->get_city_data($ipaddr);
    my $isp     = $self->get_isp_data($ipaddr);
    my $anon    = $self->get_anon_data($ipaddr);
    my %data    = (%$city, %$isp, %$anon);
    $log->debug("GEOIP returns ",{filter=>\&Dumper, value => \%data});
    return { data => \%data };
}

sub get_anon_data {
    my $self    = shift;
    my $ipaddr  = shift;
    my $log     = $self->env->log;

    my $data    = try {
        my $anon    = $self->anondb->anonymous_ip;
        return {
            is_anonymous        => $anon->is_anonymous,
            is_anonymous_vpn    => $anon->is_anonymous_vpn,
            is_hosting_provider => $anon->is_hosting_provider,
            is_public_proxy     => $anon->is_public_proxy,
            is_tor_exit_node    => $anon->is_tor_exit_node,
        };
    }
    catch {
        return {
            is_anonymous        => 0,
            is_anonymous_vpn    => 0,
            is_hosting_provider => 0,
            is_public_proxy     => 0,
            is_tor_exit_node    => 0,
        };
    };
    $log->debug("Got Anon Data: ", {filter => \&Dumper, value=> $data});
    return $data;
}

sub get_city_data {
    my $self    = shift;
    my $ipaddr  = shift;
    my $log     = $self->env->log;

    my $data    = try {
        my $city    = $self->citydb->city( ip => $ipaddr );
        return {
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
        my $message = $_;
        if ( $self->is_not_public_ipaddr($message)){
            return {
                city    => 'rfc1918',
                country => 'rfc1918',
                isocode => 'rfc1918',
                continent => 'rfc1918',
                # Atlantis?
                latitude  => '31.030488',
                longitude => '-75.275650',
            };
        }
        return {};  # unknown
    };
    $log->debug("Got City data: ",{filter=>\&Dumper, value=>$data});
    return $data;
}

sub get_isp_data {
    my $self    = shift;
    my $ipaddr  = shift;
    my $log     = $self->env->log;

    my $data    = try {
        my $isp = $self->ispdb->isp( ip => $ipaddr );
        return {
            asorg       => $isp->autonomous_system_organization,
            asn         => $isp->autonomous_system_number,
            isp         => $isp->isp,
            org         => $isp->organization,
        };
    }
    catch {
        my $message = $_;
        if ( $self->is_not_public_ipaddr($message)){
            return {
                asorg   => 'rfc1918',
                asn     => 'rfc1918',
                isp     => 'rfc1918',
                org     => 'rfc1918',
            };
        }
        return {}; #unknown
    };
}

sub is_not_public_ipaddr {
    my $self    = shift;
    my $message = shift;
    return ($message =~ /not a public IP/);
}

1;
