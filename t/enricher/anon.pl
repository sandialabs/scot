#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);
use GeoIP2::Database::Reader;
use Data::Dumper;

my $anondb  = GeoIP2::Database::Reader->new(
    file => '/usr/share/GeoIP/GeoIP2-Anonymous-IP.mmdb', 
    locales => [ 'en' ]
);

my @ips = (qw(
        45.77.121.161
));

foreach my $ip (@ips) {
    my $rec = $anondb->anonymous_ip(ip => $ip);
    say Dumper($rec);
}
    
