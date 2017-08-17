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

    return $self->create({
        vertices   => $vertices,
        weight      => $weight,
        when        => $when,
    });
};

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
    my $match   = {
        id      => $object->id,
        type    => $object->get_collection_name,
    };
    my $cursor  = $self->find({
        vertices    => { '$elemMatch' => $match }
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
    my $object  = shift; # scot model or hashref
    my $type    = shift;
    my $objid;
    my $objtype;

    my $match   = $self->get_vertex($object);

    my @agg     = (
        { 
            '$match' => { 
                vertices => { 
                    '$elemMatch' => $match,
                },
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
        vertices    => { '$elemMatch' => { id => $id, type => "entity" }},
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
    });
    $self->env->log->debug("found ".$cursor->count." links");
    return $cursor;
}

sub get_display_count {
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
                    '$elemMatch' => { 
                        id      => $entity->id, 
                        type    => 'entity',
                    }
                }
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

    my $lcursor     = $self->get_object_links_of_type($object,$type);
    my @linked_ids  = map {$_->{vertices}->{id}} $lcursor->all;
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
    else {
        $vertex = $thing;  # assuming hash
    }
    return $vertex;
}


1;
