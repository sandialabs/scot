package Scot::Role::Historable;

use Moose::Role;

1;

=head1 Name

Scot::Role::Historable

=head1 Description

This role, when consumed by a Scot::Model, signifies that this object
may have a series of Scot::Model::History objects associated with it.

=head1 Synopsis

    if ( $obj->does_role('Scot::Role::History') ) {
        print "This object might have a history!\n";
    }

=cut


1;
