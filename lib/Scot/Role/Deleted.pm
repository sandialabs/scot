package Scot::Role::Deleted;

use Moose::Role;

=item B<deleted>

NOT USED, but saved as an alertnate implementation possibility 
if the current method of moving data to a deleted collection
proves not to be the way to do it.

Mark the consuming object as deleted, which should prevent
display, but not actually remove record from collection.
To truly remove, we will do a "purge"

=cut

has deleted => (
    is          => 'ro',
    isa         => 'Bool',
    traits      => ['Bool'],
    required    => 1,
    default     => 0,
    handles     => {
        delete      => 'set',
        undelete    => 'unset',
    },
);

1;
