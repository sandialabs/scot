package Scot::Role::Sources;

use Moose::Role;
use namespace::autoclean;

=item B<source>

signals the api.pm that this model might have sources 

=cut

has source => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [] },
);

1;
