package Scot::Role::Updated;

use Moose::Role;

=item B<updated>

The seconds since the unix epoch when the consuming model was last updated

=cut

has updated => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => sub { time(); },
);

1;
