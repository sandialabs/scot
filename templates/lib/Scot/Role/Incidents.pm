package Scot::Role::Incidents;

use Moose::Role;

=item B<incidents>

Array of incidents id's that the cosuming model is related to

=cut

has incidents => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    required=> 1,
    default => sub {[]},
);

1;
