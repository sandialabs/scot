package Scot::Role::Tags;

use Moose::Role;
use namespace::autoclean;

=item B<tags>

Array of tags applied to consuming object

=cut

has tags => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    required    => 1,
    default => sub {[]},
);

1;
