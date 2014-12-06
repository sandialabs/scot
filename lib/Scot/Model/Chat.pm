package Scot::Model::Chat;

use lib '../../lib';
use strict;
use warnings;
use v5.10;

use Moose;
use namespace::autoclean;

extends 'Scot::Model';

with (
    'Scot::Roles::Dumpable',
    'Scot::Roles::Hashable',
);

has room    => (
    is      => 'rw',
    isa     => 'Str',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

has when    => (
    is      => 'rw',
    isa     => 'Int',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        alt_data_sub    => 'fmt_time',
    },
);

has what    => (
    is      => 'rw',
    isa     => 'Str',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

1;
