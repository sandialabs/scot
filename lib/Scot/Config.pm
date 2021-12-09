package Scot::Config;

use strict;
use warnings;
use Moose;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;
use Config::JSON;
use lib '../../lib';

has file => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has config => (
    is          => 'ro',
    isa         => 'Config::JSON',
    required    => 1,
    lazy        => 1,
    builder     => 'build_config_data',
);

sub build_config_data ($self) {
    my $file    = $self->file;
    return Config::JSON->new(pathToFile=>$file);
}

1;
