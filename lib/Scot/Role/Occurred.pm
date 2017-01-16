package Scot::Role::Occurred;

use Moose::Role;
use namespace::autoclean;

=item B<occurred>

Array of times in secs since epoch when consuming object has 
appeared in scot
(most likely tags and entities)

=cut

has occurred => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    required    => 1,
    default => sub {[]},
);

1;
