package Scot::Role::Parsed;

use Moose::Role;

=item B<parsed>

Was the consuming model parsed? (true = 1) 

=cut

has parsed => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

1;
