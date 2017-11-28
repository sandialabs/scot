package Scot::Role::Alerts;

use Moose::Role;

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

1;
