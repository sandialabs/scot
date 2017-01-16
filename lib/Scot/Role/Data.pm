package Scot::Role::Data;

use Moose::Role;

=item B<data>

The consuming model uses this store a complex data structure
usually the Alert data

=cut

has data => (
    is          => 'ro',
    isa         => 'HashRef',
    traits      => [ 'Hash' ],
    required    => 1,
    default     => sub {{}},
);

1;
