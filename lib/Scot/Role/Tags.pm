package Scot::Role::Tags;

use Moose::Role;
use namespace::autoclean;

=item B<tag>

Tags may be applied to consuming object.
Tags are in their own collection with a targets array 

=cut

has tag    => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [] },
);

1;
