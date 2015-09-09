package Scot::Role::Username;

use Moose::Role;

=item B<username>

The username string

=cut

has username => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '',
);

1;
