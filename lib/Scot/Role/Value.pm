package Scot::Role::Value;

use namespace::autoclean;

use Moose::Role;

=item C<value>

 the value or name of something

=cut

has value  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

1;
