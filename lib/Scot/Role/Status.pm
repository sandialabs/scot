package Scot::Role::Status;

use Moose::Role;

=item B<status>

The status of the consuming model.

=cut

has status => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'open',
);

1;
