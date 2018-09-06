package Scot::Role::Entitiable;
use Moose::Role;

=head1 Name

Scot::Role::Entitiable

=head1 Description

This role, when consumed by a Scot::Model, signifies that this object
can have Entities associated it.  This allows for code to check by doing:

=head1 Synopsis

    if ( $obj->does_role('Scot::Role::Entitiable') ) {
        print "This object can have entities in it\n";
    }

=cut


1;
