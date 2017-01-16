package Scot::Role::Target;

use Moose::Role;

=item B<target>

a target is a hashref of
{ type => $type, id => $id }

=cut

has target  => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => [ 'Hash' ],
    required=> 1,
    default => sub {{}},
);

1;
