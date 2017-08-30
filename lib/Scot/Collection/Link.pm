package Scot::Collection::Link;

use lib '../../../lib';
use Data::Dumper;
use Try::Tiny;
use Moose 2;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
);

override api_create => sub {
    my $self    = shift;
    my $href    = shift;    # the $req from the web api
    my $log     = $self->env->log;
    my $json    = $href->{request}->{json};

    my $vertices    = $json->{vertices};
    my $weight  = $json->{weight} // 1;
    my $when    = $json->{when} // $self->env->now;

    $log->debug("api_create link with: ",{filter=>\&Dumper, value=>$vertices});

    # check if it exists already
    if ( my $link = $self->find_one({vertices => $vertices}) ) {
        return $link;
    }
    else {
        return $self->create({
            vertices   => $vertices,
            weight      => $weight,
            when        => $when,
        });
    }
};

sub get_vertex {
    my $self    = shift;
    my $thing   = shift;
    my $vertex  = shift;

    if ( ref($thing) =~ /Scot::Model/ ) {
        $vertex = { 
            id      => $thing->id,
            type    => $thing->get_collection_name,
        };
    }
    elsif (ref($thing) eq "HASH" )  {
        $vertex = $thing;  # assuming hash
    }
    else {
        die "Invalid Object provided to get_vertex";
    }
    return $vertex;
}

sub link_objects {
    my $self    = shift;
    my $v0      = shift; # object(scot::model) or href
    my $v1      = shift; # object(scot::model) or href
    my $options = shift; # href 
    my $weight  = $options->{weight} // 1;
    my $when    = $options->{when} // $self->env->now;

    my @vertices = (
        $self->get_vertex($v0),
        $self->get_vertex($v1),
    );

    return $self->create({
        vertices  =>  \@vertices,
        weight  => $weight,
        when    => $when,
    });
}

sub get_object_links {
    my $self    = shift;
    my $object  = shift;
    my $type;
    my $id;

    my $vertex = $self->get_vertex($object);


    my $cursor  = $self->find({
        vertices    => {
            '$elemMatch' => {
                id      => $vertex->{id},
                type    => $vertex->{type},
            },
        },
    });
    return $cursor;
}


sub get_entity_links_by_value {
    my $self    = shift;
    my $value   = shift;
    my $entitycol   = $self->mongo->collection('Entity');
    my $entityobj   = $entitycol->find({value => $value});
    return $self->get_object_links($entityobj);
}

sub get_object_links_of_type {
    my $self    = shift;
    my $object  = shift;
    my $type    = shift;
    my $vertex  = $self->get_vertex($object);
    my $match   = {
        '$and'  => [
            { vertices => { '$elemMatch' => $vertex } },
            { 'vertices.type'   => $type },
        ],
    };
    my $cursor  = $self->find($match);
    return $cursor;
}

sub get_object_links_of_type_agg {
    my $self    = shift;
    my $object  = shift; # scot model or hashref
    my $type    = shift;
    my $objid;
    my $objtype;

    my $match   = $self->get_vertex($object);

    my @agg     = (
        { 
            '$match' => { 
                vertices => $match,
            },
        },
        {
            '$unwind'   => '$vertices',
        },
    );

    if ( ! defined $type ) {
        push @agg, {
            '$match'    => { 
                '$or' =>  [ 
                    {'vertices.type' => {'$ne' => $match->{type}} }, 
                    {'vertices.id'   => {'$ne' => $match->{id}} }, 
                ]
            },
        };
    }
    else {
        push @agg, {
            '$match'    => { 'vertices.type'    => $type },
        };
    }
    my $cursor  = $self->_mongo_collection->aggregate(\@agg);
    return $cursor;
}
                

sub get_links_by_entity_id {
    my $self    = shift;
    my $id      = shift;
    my $cursor  = $self->find({ 
        vertices    => { id => $id, type => "entity" },
    });
    return $cursor;
}

sub get_links_by_target {
    my $self    = shift;
    my $target  = shift;
    my $id      = $target->{id} + 0;
    my $type    = $target->{type};

    $self->env->log->debug("Finding Links to $type $id");
    my $cursor = $self->find({
         vertices    => { '$elemMatch' => { id => $id, type => $type } },
    #     vertices => { id => $id, type => $type }
    });
    $self->env->log->debug("found ".$cursor->count." links");
    return $cursor;
}

sub get_display_count {
    my $self    = shift;
    my $entity  = shift;
    my $vertex  = $self->get_vertex($entity);
    # count times linked to Alergroup, Event, Intel, Incident, Guide, Signature...
    # excluding alert and entry because that can be multiple times per Event, etc.
    my $match   = {
        '$and'  => [
            {vertices => { '$elemMatch' => $vertex } },
            {'vertices.type' => { '$nin' => [ 'alert', 'entry' ] } },
        ],
    };
    my $cursor  = $self->find($match);
    return $cursor->count;
}

sub get_display_count_agg {
    my $self    = shift;
    my $entity  = shift;
    my $log     = $self->env->log;

    $log->debug("Counting links to entity");

    if ( $entity->status eq "untracked" ) {
        $log->debug("untracked entity");
        return 0;
    }

    my @agg = (
        { 
            '$match' => {
                vertices    => { 
                    id      => $entity->id, 
                    type    => 'entity',
                },
            }
        },
        { '$unwind' => '$vertices' },
        { '$match'  => { 
            'vertices.type' => { '$nin' => [ 'alertgroup', 'entry' ] }
        }},
    );
    # need to benchmark, if this is slow, it can kill scot workers
    my $query_result  = $self->_mongo_collection->aggregate(\@agg);
    return scalar($query_result->all);
}

sub get_linked_objects_cursor {
    my $self    = shift;
    my $object  = shift;     # href or scot::model
    my $type    = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    $log->debug("get_linked_objects_cursor of object ".
                ref($object)." and type $type");

    my $targetvertex = $self->get_vertex($object);

    my $lcursor     = $self->get_object_links_of_type($object,$type);
    # my @linked_ids  = map {$_->{vertices}->{id}} $lcursor->all; # this worked for agg style not other
    my @linked_ids  = ();
    while ( my $link = $lcursor->next ) {
        my $varef   = $link->vertices;
        if ( $varef->[0]->{type} eq $targetvertex->{type} and
             $varef->[0]->{id} == $targetvertex->{id} ) {
            push @linked_ids, $varef->[1]->{id};
        }
        else {
            push @linked_ids, $varef->[0]->{id};
        }
    }

    my $match       = { id => { '$in' => \@linked_ids }};
    my $lo_cursor   = $mongo->collection(ucfirst($type))->find($match);
    return $lo_cursor;
}

sub link_exists {
    my $self    = shift;
    my $obj1    = shift; # scot::model or href
    my $obj2    = shift; # scot::model or href

    my @vertices = (
        $self->get_vertex($obj1),
        $self->get_vertex($obj2)
    );

    my $linkobj = $self->find_one({vertices => { '$all' => \@vertices }});

    return defined $linkobj;
}


1;
