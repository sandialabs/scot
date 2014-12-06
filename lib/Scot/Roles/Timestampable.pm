package Scot::Roles::Timestampable;

use Moose::Role;
use Data::Dumper;
use Time::HiRes qw(gettimeofday);
use namespace::autoclean;


sub _timestamp {
    my $self        = shift;
    my ($seconds,
        $micros)    = gettimeofday();
    return $seconds;
}

1;

