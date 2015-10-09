package Scot::Role::Type;

use Moose::Role;

=item B<type>

The string representation of a "type" attribute

=cut

has type => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '',
);

1;
