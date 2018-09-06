package Scot::Role::When;
use Moose::Role;

=head1 Name

Scot::Role::When

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<when>

the integer number of seconds of "when" something occurred.
This is the only user changable timestamp

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
