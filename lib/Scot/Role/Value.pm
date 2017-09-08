package Scot::Role::Value;

use Moose::Role;

=item B<value>

the name or value 

=cut

has value    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => ' ',
);

1;
