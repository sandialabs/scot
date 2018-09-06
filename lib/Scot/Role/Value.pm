package Scot::Role::Value;
use Moose::Role;
use namespace::autoclean;

=head1 Name

Scot::Role::Value

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item C<value>

 the value or name of something

=cut

has value  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

=back

=cut

1;
