package Scot::Model::Permittedsender;

use lib '../../lib';
use strict;
use warnings;
use v5.10;

use Data::Dumper;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

=head1 NAME
 Scot::Model::Permittedsender - a moose obj rep of a Scot Permittedsender

=head1 DESCRIPTION

Permitted senders contain sender (username) and domains that are
allowed to send alerts to SCOT.  Both sender and and domain may be regexes

=cut

extends 'Scot::Model';

=head2 Attributes

=cut
with (  
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Hashable',
    'Scot::Roles::Loggable',
);

has permittedsender_id  => (
    is      => 'rw',
    isa     => 'Int',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<idfield>

 since my integer id fields in models include the model name in them 
 instead of just "id", this field gives us an easy way to figure out
 what the id attribute is.  We can debate the original choice later...

=cut

has idfield    => (
    is          => 'ro',
    isa         => 'Str',
    required    =>  1,
    default     => 'permittedsender_id',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<collection>

 easy way to keep track of object to collection mapping.  
 We can debate the original choice later...

=cut

has collection => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'permittedsenders',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<sender>

 regex of permitted sender

=cut

has sender     => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => '',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<domain>

 regex of permitted domain

=cut

has domain     => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);


 __PACKAGE__->meta->make_immutable;
1;
