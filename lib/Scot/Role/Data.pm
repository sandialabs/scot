package Scot::Role::Data;
use Moose::Role;

=head1 Name

Scot::Role::Data

=head1 Description

This Role, when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<data>

A HashRef that allows the storage of arbitrary JSON within the consuming object.
A reference to an empty Hash is permitted.

=cut

has data => (
    is          => 'ro',
    isa         => 'HashRef',
    traits      => [ 'Hash' ],
    required    => 1,
    default     => sub {{}},
);

=back 

=cut

1;
