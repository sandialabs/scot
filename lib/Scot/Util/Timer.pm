package Scot::Util::Timer;

use lib '../../../lib';
use v5.10;
use strict;
use warnings;

use Time::HiRes qw(gettimeofday tv_interval);

use Moose;

has timer   => (
    is          => 'rw',
    isa         => 'CodeRef',
    required    => 1,
    builder     => '_start_timer',
);

sub _start_timer {
    my $self    = shift;
    my $start   = [ gettimeofday ];
    return sub {
        my $begin   = $start;
        my $elapsed = tv_interval( $begin, [ gettimeofday ] );
        return $elapsed;
    };
}

__PACKAGE__->meta->make_immutable;
1;
