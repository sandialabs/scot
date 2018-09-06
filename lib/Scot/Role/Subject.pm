package Scot::Role::Subject;
use Moose::Role;

=head1 Name

Scot::Role::Subject

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<Subject>

The subject of the consuming model.  A string.

=back

=cut

has subject => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '',
);

1;
