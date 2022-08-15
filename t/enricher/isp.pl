#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);
use GeoIP2::Database::Reader;
use Data::Dumper;

my $ispdb  = GeoIP2::Database::Reader->new(
    file => '/usr/share/GeoIP/GeoIP2-ISP.mmdb', 
    locales => [ 'en' ]
);

my @ips = (qw(
        45.77.121.1
        45.77.121.2
        45.77.121.3
        45.77.121.4
        45.77.121.5
        45.77.121.6
        45.77.121.7
));

foreach my $ip (@ips) {
    my $rec = $anondb->anonymous_ip(ip => $ip);
    say Dumper($rec);
}
    
