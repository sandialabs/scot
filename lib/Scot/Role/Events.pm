package Scot::Role::Events;
use Moose::Role;

=head1 Name

Scot::Role::Events

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<events>

Array of event id's that the cosuming model is related to

=back

=cut

has events => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    required=> 1,
    default => sub {[]},
);

1;
