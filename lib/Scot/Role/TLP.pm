package Scot::Role::TLP;

use Moose::Role;


=item B<tlp>

the TLP "color"

=cut

has tlp    => (
    is          => 'ro',
    isa         => enum([qw(unset white green amber red)]),
    required    => 1,
    default     => 'unset',
);

1;
