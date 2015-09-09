package Scot::Role::When;

use Moose::Role;

=item B<when>

the integer number of seconds of "when" something occurred.
This is the only user changable timestamp

=cut

has when    => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => sub { time(); },
);

1;
