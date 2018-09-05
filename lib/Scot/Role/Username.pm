package Scot::Role::Username;
use Moose::Role;

=head1 Name

Scot::Role::Username

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<username>

The username string

=cut

has username => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '',
);

=back

=cut

1;
