package Scot::Role::Status;
use Moose::Role;

=head1 Name

Scot::Role::Status

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<status>

The status of the consuming model.  A string value.  Usually "open",
"closed", or "promoted".

=back

=cut

has status => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'open',
);

1;
