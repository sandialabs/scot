package Scot::Role::Promotable;

use Moose::Role;

=item B<promotions>

###
### removing this to be replaced with Link.pm
###

Hash that tracks what was promoted to this thing
and what this thing was promoted to.  Multi to multi
{
    from => [
        { type => $type, id => $id }, ...
    ],
    to  => [
        { type => $type, id => $id }, ...
    ],
}


# no longer used == use link collection

has promotions => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => [ 'Hash' ],
    required=> 1,
    default => sub { 
        {
            from    => [],
            to      => [],
        } 
    },
);

=cut

1;
