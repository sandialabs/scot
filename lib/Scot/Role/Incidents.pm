package Scot::Role::Incidents;
use Moose::Role;

=head1 Name

Scot::Role::Incidents

=head1 Description

This role, when consumed by a Scot::Model, provides the following attributes:

=head1 Attributes

=over 4

=item B<incidents>

Array of incidents id's that the cosuming model is related to

=back

=cut

has incidents => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    required=> 1,
    default => sub {[]},
);

1;
