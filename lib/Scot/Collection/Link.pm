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
    my $weight      = $json->{weight}   // 1;
    my $when        = $json->{when}     // $self->env->now;
    my $memo        = $json->{memo};
    my $context     = $json->{context} // ' ';

    $log->debug("api_create link with: ",{filter=>\&Dumper, value=>$vertices});

    if ( $self->vertices_input_is_invalid($vertices) ) {
        die "Invalid vertices in link api_create";
    }

    if ( ref($memo) ne "ARRAY" ) {
        
        $log->warn( "Invalid link memos");
        $memo = [ 
            $self->get_vertex_memo($vertices->[0]),
            $self->get_vertex_memo($vertices->[1])
        ];
        $log->warn( "Setting link memos", {filter=>\&Dumper, value=>$memo});
    }

    # check if it exists already
    my $match = { vertices => { '$all' => $vertices } };
    if ( my $link = $self->find_one($match) ) {
        return $link;
    }
    return $self->create({
        vertices    => $vertices,
        weight      => $weight,
        when        => $when,
        memo        => $memo,
        context     => $context,
    });
};

sub vertices_input_is_invalid {
    my $self    = shift;
    my $v       = shift;

    return 1 if ( ref($v) ne "ARRAY" );
    return 1 if ( ref($v->[0]) ne "HASH");
    return 1 if ( ref($v->[1]) ne "HASH");
    return 1 if ( ! defined $v->[0]->{type} );
    return 1 if ( ! defined $v->[1]->{type} );
    return 1 if ( ! defined $v->[0]->{id} );
    return 1 if ( ! defined $v->[1]->{id} );
    return undef;
}

sub thing_is_vertex {
    my $self    = shift;
    my $thing   = shift;
    my $log     = $self->env->log;

    if ( ref($thing) eq "HASH" ) {
        $log->debug("thing is a HASH");
        if ( defined $thing->{id} and defined $thing->{type} ) {
            $log->debug("thing has an id and type");
            return 1;
        }
    }
    return undef;

}


sub get_vertex {
    my $self    = shift;
    my $thing   = shift;

    if ( ref($thing) =~ /Scot::Model/ ) {
        return { 
            id      => $thing->id + 0,
            type    => $thing->get_collection_name,
        };
    }
    if (ref($thing) eq "HASH" )  {
        return $thing;
    }
    die "Invalid Object provided to get_vertex";
}

sub get_vertex_object {
    my $self    = shift;
    my $vertex  = shift;

    if ( ref($vertex) ne "HASH" ) {
        die "Must provide get_vertex_object with a vertex Hash Ref";
    }
    my $id      = $vertex->{id} + 0;
    my $type    = $vertex->{type};
    my $col     = $self->env->mongo->collection(ucfirst($type));
    my $obj     = $col->find_iid($id);
    return $obj;
}

sub get_vertex_memo {
    my $self    = shift;
    my $thing   = shift;
    my $log     = $self->env->log;

    $log->trace("Thing is ",{filter=>\&Dumper, value=>$thing});
    if ( $self->thing_is_vertex($thing) ) {
        $thing = $self->get_vertex_object($thing);
        $log->debug("Thing is now ".ref($thing));
    }


    if ( ! ref($thing) =~ /Scot::Model/ ) {
        die "Invalid input to get_vertex_memo";
    }


    if ( $thing->meta->does_role("Scot::Role::Subject") ) {
        # Alertgroup, Checklist, Event, Guide, Incident, Intel
        return $thing->subject;
    }

    if ( $thing->meta->does_role("Scot::Role::Value") ) {
        # Appearance, Entity, Source, Stat, Tag
        return $thing->value;
    }

    if ( ref($thing) eq "Scot::Model::Signature" ) {
        return $thing->name;
    }

    $self->env->log->warn("Do not know what to provide as memo for ".ref($thing));
    return " ";
}

sub link_objects {
    my $self    = shift;
    my $v0      = shift; # object(scot::model) or href
    my $v1      = shift; # object(scot::model) or href
    my $options = shift; # href 
    my $weight  = $options->{weight} // 1;
    my $when    = $options->{when} // $self->env->now;
    my $context = $options->{context} // ' ';

    my @vertices = (
        $self->get_vertex($v0),
        $self->get_vertex($v1),
    );

    my @memos   = (
        $self->get_vertex_memo($v0),
        $self->get_vertex_memo($v1),
    );

    my $match = { vertices => { '$all' => [
        { '$elemMatch'  => $vertices[0] },
        { '$elemMatch'  => $vertices[1] },
    ]}};
    my $link = $self->find_one($match); 

    $self->env->log->debug("HEY DUDE: Link match is ",{filter=>\&Dumper, value=>$match});
    $self->env->log->debug("HEY DUDE: Link match is ",{filter=>\&Dumper, value=>$link});

    if (defined $link ) {
        $self->env->log->debug("Link exists, returning a pointer");
        return $link;
    }
    $self->env->log->debug("Link does not exist already, creating...");

    return $self->create({
        vertices    =>  \@vertices,
        weight      => $weight,
        when        => $when,
        memo        => \@memos,
        context     => $context,
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
    });
    # $self->env->log->debug("found ".$cursor->count." links");
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
            {'vertices.type' => { '$nin' => [ 'alertgroup', 'entry' ] } },
        ],
    };
    my $count  = $self->count($match);
    return $count;
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

    my $match = { vertices => { '$all' => [
        { '$elemMatch'  => $vertices[0] },
        { '$elemMatch'  => $vertices[1] },
    ]}};
    my $linkobj = $self->find_one($match);

    return defined $linkobj;
}


1;
