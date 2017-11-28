package Scot::Role::Entriable;

# this Role lets SCOT know that this object can have Entries
# and that when doing /scot/api/x/event/y/entry 
# not to look in the link collection but look for matching
# entry.target.type and entry.target.id

use Moose::Role;

has entry_count => (
    is          => 'ro',
    isa         => 'Num',
    traits      => [ 'Counter' ],
    required    => 1,
    default     => 0,
#    handles     => {
#        inc_entry_count => 'inc',
#        dec_entry_count => 'dec',
#        reset_entry_count   => 'reset',
#    }
);


1;
