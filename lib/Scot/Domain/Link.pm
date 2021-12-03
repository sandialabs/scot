package Scot::Domain::Link;

use strict;
use warnings;
use Moose;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;

extends 'Scot::Domain';

sub _build_collection ($self) {
    return $self->mongo->collection('Link');
}

sub get_entity_id_set ($self, $target) {
    my $cursor  = $self->get_link_cursor_by_target($target);
    my @eid     = ();

    while ( my $link    = $cursor->next ) {
        if ( $link->vertices->[0]->{type} eq "entity" ) {
            push @eid, $link->vertices->[0]->{id};
        }
        if ( $link->vertices->[1]->{type} eq "entity" ) {
            push @eid, $link->vertices->[1]->{id};
        }
    }
    return wantarray ? @eid : \@eid;
}

sub get_link_cursor_by_target ($self, $target, $filter=undef) {

    my $query   = { 
        vertices => { '$elemMatch' =>  $target },
    };
    if ( defined $filter ) {
        $query  = {
            '$and'  => [
                { vertices => { '$elemMatch' => $target }},
                { 
                    'vertices.type'   => {
                        '$nin'  => [qw(alert alertgroup entry)],
                    }
                },
            ],
        };
    }
    my $cursor = $self->collection->find($query);
    return $cursor;
}


1;
