package Scot::Role::Originator;

use Moose::Role;


=item B<originator>

the TLP "color"

=cut

has originator  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'unknown',
);

1;
