package Scot::Role::Created;

use Moose::Role;

=item B<created>

The number of seconds since the unix epoch when the consuming model was
created.

=cut

has created => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => sub { time(); },
);

1;
