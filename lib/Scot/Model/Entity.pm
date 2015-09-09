package Scot::Model::Entity;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Entity

=head1 Description

The model of an individual Entity
use this if Entities move back into MongoDB
if we continue with Redis we will have to invent something else.

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
    Scot::Role::Occurred
    Scot::Role::Targets
);

=head1 Attributes

=over 4

=item B<value>

the string that is the entity

=cut

has value  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '',
);

=item B<type>

the type of entity

=cut

has type  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '',
);

=item B<targets>

array of hash references of form { target_type => t, target_id => i }
from Scot::Role::Target

=cut

=item B<classes>

Array of css classes to flair this entity with

=cut

has classes => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    required    => 1,
    default => sub {[]},
);


__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
