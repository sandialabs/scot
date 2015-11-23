package Scot::Role::Targets;

use Moose::Role;

=item B<targets>

Array of hash references of form { type => t, id => i }
The consuming model will use this to track what this is applied against

=cut

has targets => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    required=> 1,
    default => sub {[]},
);

1;
