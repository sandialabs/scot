package Scot::Config;

use lib '../../lib';
use v5.18;
use strict;
use warnings;
use Safe;

use Moose;

has filename => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has config  => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_config',
);

sub _build_config {
    my $self    = shift;
    my $file    = $self->filename;

    unless ( -e $file ) {
        die "Unable to load config file $file\n";
    }

    my $compartment = new Safe 'CONFIG';
    my $rc          = $compartment->rdo($file);
    return \%CONFIG::config;
}

1;
