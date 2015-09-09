package Scot::Role::Events;

use Moose::Role;

=item B<events>

Array of event id's that the cosuming model is related to

=cut

has events => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    required=> 1,
    default => sub {[]},
);

1;
