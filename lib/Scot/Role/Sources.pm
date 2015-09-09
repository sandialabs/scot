package Scot::Role::Sources;

use Moose::Role;
use namespace::autoclean;

=item B<sources>

Array of sources applied to consuming object

=cut

has sources => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    required    => 1,
    default => sub {[]},
);

1;
