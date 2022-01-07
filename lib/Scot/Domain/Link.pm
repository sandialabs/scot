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

sub find_linked_by_type ($self, $type_to_return, $target) {
    my $query   = {
        '$and'  => [
            { vertices  => { '$elemMatch' => $target } },
            { 'vertices.type' => $type_to_return },
        ],
    };
    $self->log->debug("find_linked_by_type query ", {filter=>\&Dumper, value=>$query});
    my $cursor  = $self->collection->find($query);
    my @result  = ();
    while ( my $link = $cursor->next ) {
        my $href    = $link->as_hash;
        push @result, $href;
    }
    return wantarray ? @result : \@result;
}

sub link_objects ($self, $obj1, $obj2, $options=undef) {
    my $weight  = $options->{weight} // 1;
    my $when    = $options->{when} // time();
    my $context = $options->{context} // '';

    my $vertex1 = $self->get_vertex($obj1);
    my $memo1   = $obj1->get_memo();
    my $vertex2 = $self->get_vertex($obj2);
    my $memo2   = $obj2->get_memo();

    my $query   = {
        vertices    => {
            '$all'  => [
                { '$elemMatch'  => $vertex1 },
                { '$elemMatch'  => $vertex2 },
            ]
        }
    };
    my $link    = $self->collection->find_one($query);

    if (defined $link) {
        # maybe increase weight?
        return $link;   # link already exists;
    }

    my $data    = {
        vertices    => [ $vertex1, $vertex2 ],
        weight      => $weight,
        when        => $when,
        memo        => [ $memo1, $memo2 ],
        context     => $context,
    };
    $link   = $self->collection->create($data);
    return $link;
}

sub get_vertex ($self, $object) {
    my $id      = $object->id + 0;
    my $type    = $object->get_collection_name;
    return { type => $type, id => $id };
}


1;
