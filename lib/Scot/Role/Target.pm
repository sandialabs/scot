package Scot::Role::Target1;

use Moose::Role;

=item B<target>

a target is a hashref of
{ type => $type, id => $id }

=cut

has targets => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => [ 'Hash' ],
    required=> 1,
    default => sub {{}},
);

1;
