package Scot::Role::Owner;

use namespace::autoclean;

use Moose::Role;

=item C<owner>

 string representation of the username that owns this thing

=cut

has owner  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

1;
