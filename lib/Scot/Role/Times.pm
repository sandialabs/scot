package Scot::Role::Times;

use Moose::Role;

=item B<updated>

The seconds since the unix epoch when the consuming model was last updated

=cut

has updated => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => sub { time(); },
);

=item B<created>

when it was created

=cut

has created => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => sub { time(); },
);

=item B<when>

user adjustable time

=cut

has when    => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => sub { time(); },
);

1;
