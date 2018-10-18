package Scot::Role::Alerts;
use Moose::Role;

=head1 Name

Scot::Role::Alerts

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<alerts>

Array of alert id's that the cosuming model is related to

=cut

has alerts => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    required=> 1,
    default => sub {[]},
);

=back

=head1 License

http://www.apache.org/licenses/LICENSE-2.0

=cut


1;
