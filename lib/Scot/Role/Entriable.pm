package Scot::Role::Entriable;
use Moose::Role;

# this Role lets SCOT know that this object can have Entries
# and that when doing /scot/api/x/event/y/entry 
# not to look in the link collection but look for matching
# entry.target.type and entry.target.id

=head1 Name

Scot::Role::Entriable

=head1 Description

This role, when consumed by a Scot::Model, signifies that the object may
have entries associated with it.  It also provides the following attribues:

=head1 Synopsis

    if ( $obj->does_role('Scot::Role::Entriable') {
        say "Object has ".$obj->entry_count." entries posted";
    }

=head1 Attributes

=over 4

=item B<entry_count>

The integer number of entries associated with this object.  Note: the 
controller code must update this count with entries are added, or deleted.

=back

=cut

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
