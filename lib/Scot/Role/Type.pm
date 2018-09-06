package Scot::Role::Type;
use Moose::Role;

=head1 Name

Scot::Role::Type

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<type>

The string representation of a "type" attribute

=cut

has type => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '',
);

=back

=cut

1;
