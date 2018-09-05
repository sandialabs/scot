package Scot::Role::Times;
use Moose::Role;

=head1 Name

Scot::Role::Times

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<updated>

The seconds since the unix epoch when the consuming model was last updated

=cut

has updated => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => sub { time(); },
);

=item B<created>

when it was created (integer seconds since unix epoch)

=cut

has created => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => sub { time(); },
);

=item B<when>

user adjustable time (integer seconds since unix epoch)

=cut

has when    => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => sub { time(); },
);

=back

=cut

1;
