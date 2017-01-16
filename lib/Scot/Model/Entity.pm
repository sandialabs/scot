package Scot::Model::Entity;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Entity

=head1 Description

The model of an individual Entity

Entities are linked to other items via
the Link collection

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Entriable
    Scot::Role::Hashable
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


=item B<data>

hold data in a key value store about the entity.
not sure what this will be but it is a safety valve 

=cut

has data    => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => [ 'Hash' ],
    required    => 1,
    default => sub {{}},
);

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
