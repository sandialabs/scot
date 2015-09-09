package Scot::Role::Subject;

use Moose::Role;

=item B<Subject>

The subject of the consuming model.

=cut

has subject => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '',
);

1;
