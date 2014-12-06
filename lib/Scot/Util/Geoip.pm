package Scot::Util::Geoip;

use lib '../../../lib';
use lib '../lib';
use strict;
use warnings;
use v5.10;

use Data::Dumper;
use Geo::IP;
use Moose;
use namespace::autoclean;

has 'log'   => (
    is          => 'ro',
    isa         => 'Object',
    required    => 1,
);

has geoip_city => (
    is          => 'rw',
    isa         => 'Maybe[Geo::IP]',
    required    => 1,
    builder     => '_build_city_handle',
);

has geoip_org => (
    is          => 'rw',
    isa         => 'Maybe[Geo::IP]',
    required    => 1,
    builder     => '_build_org_handle',
);

has geoip_v6 => (
    is          => 'rw',
    isa         => 'Maybe[Geo::IP]',
    required    => 1,
    builder     => '_build_v6_handle',
);

has geoip_v6asn => (
    is          => 'rw',
    isa         => 'Maybe[Geo::IP]',
    required    => 1,
    builder     => '_build_v6_handle',
);


sub _build_city_handle {
    my $self    = shift;
    my $geoip;
    if( -R '/usr/local/share/GeoIP/GeoIPCity.dat') { 
       $geoip   = Geo::IP->open('/usr/local/share/GeoIP/GeoIPCity.dat');
    }
    if( -R '/usr/local/share/GeoIP/GeoLiteCity.dat' ) {
       $geoip   = Geo::IP->open('/usr/local/share/GeoIP/GeoLiteCity.dat');
    }
    return $geoip;
}

sub _build_org_handle {
    my $self    = shift;
    my $geoip;
    if( -R '/usr/local/share/GeoIP/GeoIPOrg.dat') {
       $geoip   = Geo::IP->open('/usr/local/share/GeoIP/GeoIPOrg.dat');
    }
    return $geoip;
}

sub _build_v6_handle {
    my $self    = shift;
    my $geoip;
    if( -R '/usr/local/share/GeoIP/GeoIPv6.dat') { 
       $geoip   = Geo::IP->open('/usr/local/share/GeoIP/GeoIPv6.dat');
    }
    if( -R '/usr/share/GeoIP/GeoIPv6.dat') {
       my $geoip   = Geo::IP->open('/usr/share/GeoIP/GeoIPv6.dat');
    } 
    return $geoip;
}

sub _build_v6asn_handle {
    my $self    = shift;
    my $geoip;
    if( -R '/usr/local/share/GeoIP/GeoIPASNnum6.dat') {
        $geoip   = Geo::IP->open('/usr/local/share/GeoIP/GeoIPASNumv6.dat');
    }
    return $geoip;
}

sub get_geo_data {
    my $self    = shift;
    my $type    = shift;
    my $ipaddr  = shift;
    my $data    = {};

    if ( $type  eq  "ipaddr" ) {

        if ( $ipaddr ne '' and defined $ipaddr ) {
            if(defined($self->geoip_city)) {
               my $gi  = $self->geoip_city;
               my $rec = $gi->record_by_addr($ipaddr);

               if ( $rec ) {
                   $data   = $self->get_v4_info($rec, $ipaddr);
               }
               else {
                   $data   = $self->get_v6_info($ipaddr);
               }
            }
        }
    }
    return $data;
}

sub get_v4_info {
    my $self    = shift;
    my $rec     = shift;
    my $ipaddr  = shift;
    my $cc      = $rec->country_code;
    my $orgdb   = $self->geoip_org;
  
    my $org;
    if(defined($orgdb)) {
       $org     = $orgdb->name_by_addr($ipaddr);

       if ( $org   =~ /Sandia/ or
            $org   =~ /Los Alamos/ or
            $org   =~ /Department of Energy/ ) {
           $cc = $org;
       }
    }
    my $data    = {
        country_code    => $cc,
        country_name    => $rec->country_name,
        region          => $rec->region,
        org             => $org,
        city            => $rec->city,
    };
    return $data;
}

sub get_v6_info {
    my $self    = shift;
    my $ipaddr  = shift;
    my $gdb     = $self->geoip_v6;
    my $asn     = $self->geoip_v6asn;
    my $result  = {};

    my $cc;
    if(defined($gdb)) {
       $cc  = $gdb->country_code_by_addr_v6($ipaddr);
    }

    if ( defined $cc ) {
        $result = { country_code => $cc };
    }
    my $ipasn;
    if(defined($asn)) {
       $ipasn   = $asn->name_by_addr_v6($ipaddr);
    }

    if ( defined $ipasn ) {
        $result->{asn} = $ipasn;

        if ( $ipasn =~ /Sandia National Laboratories/ ) {
            $result->{country_code} = "Sandia National Laboratories";
        }
    }
    return $result;
}


__PACKAGE__->meta->make_immutable;
1;
