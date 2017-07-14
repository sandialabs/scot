package Scot::Collection::Entity;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
    Scot::Role::GetTargeted
);

sub create_from_api {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mq      = $env->mq;

    $log->trace("Creating Entity via API");

    my $request = $href->{request}->{json};
    my $value   = $request->{value};
    my $type    = $request->{type};

    if ( $self->entity_exists($value, $type) ) {
        $log->error("Error! Entity already exists");
        return undef;
    }

    my $entity  = $self->create($request);

    unless ( defined $entity ) {
        $log->error("Error! Failed to create Entity with data ",
                    { filter => \&Dumper, value => $request } );
        return undef;
    }
    # Api.pm should do this
    #$env->mq->send("scot", {
    #    action  => "created",
    #    data    => {
    #        type    => "entity",
    #        id      => $entity->id,
    #    }
    #});
    return $entity;
}

sub entity_exists {
    my $self    = shift;
    my $value   = shift;
    my $type    = shift;
    my $obj     = $self->find_one({ value => $value, type => $type });

    if ( defined $obj ) {
        return 1;
    }
    return undef;
}


sub update_entities {
    my $self    = shift;
    my $target  = shift;    # Scot::Model Object
    my $earef   = shift;    # array of hrefs that hold entityinfo

    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $thash = $target->as_hash;
    $self->env->log->debug("updating entities on target ",
                            { filter =>\&Dumper, value => $thash});

    $log->debug("earef is ",{filter=>\&Dumper, value=>$earef});

    my $type    = $target->get_collection_name;
    my $id      = $target->id;
    my $linkcol = $mongo->collection('Link');

    $log->debug("[$type $id] Updating associated entities");
    $log->debug("[$type $id] ", {filter=>\&Dumper, value=>$earef});
    
    my @created_ids = ();
    my @updated_ids = ();

    foreach my $entity (@$earef) {

        my $value   = $entity->{value};
        my $etype   = $entity->{type};
        my $entity  = $self->find_one({
            value   => $value,
            type    => $etype
        });

        if ($entity) {
            my $entity_status   = $entity->status;
            if ( $entity_status eq "untracked" ) {
                next;
            }
            $log->debug("Found matching $type entity $value");
            push @updated_ids, $entity->id;
        }
        else {
            $log->debug("Creating new $type entity $value");
            $entity = $self->create({
                value   => $value,
                type    => $etype,
            });
            push @created_ids, $entity->id;
        }
        # $log->trace("entity is ",{filter=>\&Dumper, value=>$entity});
        my $entity_id  = $entity->id;


        my $link    = $linkcol->create_link(
            $entity, { type => $type, id   => $id, }
        );

        if ( $type eq "entry" ) {
            my $target_id   = $target->target->{id};
            my $target_type = $target->target->{type};

            my $addlink = $linkcol->create_link(
                $entity, { type => $target_type, id => $target_id, }
            );
        }

        if ( $type eq "alert" ) {
            my $addlink = $linkcol->create_link(
                $entity, { type => "alertgroup", id => $target->{alertgroup} }
            );
        }
    }
    return \@created_ids, \@updated_ids;
}

sub api_subthing {
    my $self    = shift;
    my $req     = shift;
    my $thing   = $req->{collection};
    my $id      = $req->{id} + 0;
    my $subthing= $req->{subthing};
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    if ( $subthing  eq "alert" or
         $subthing  eq "event" or
         $subthing  eq "intel" or
         $subthing  eq "incident" ) {
        my @links = map { $_->{target}->{id} } 
                        $mongo->collection('Link')->find({
                            entity_id       => $id,
                            'target.type'   => $subthing,
                        })->all;
        $log->debug("Links found: ",{filter=>\&Dumper, value => \@links});
        return $mongo->collection(ucfirst($subthing))->find({
            id  => { '$in'  => \@links }
        });
    }

    if ( $subthing eq "entity" ) {
        my @links = map { $_->{id} } 
                        $mongo->collection('Link')->get_links_by_target({
                            id      => $id,
                            type    => 'entity',
                        })->all;
        return $self->find({id => {'$in' => \@links}});
    }
    if ( $subthing eq "entry" ) {
        return $mongo->collection('Entry')->get_entries_by_target({
            id  => $id,
            type    => 'entity',
        });
    }
    if ( $subthing eq "file" ) {
        return $mongo->collection('File')->find({
            'entry_target.type' => 'entity',
            'entry_target.id'   => $id,
        });
    }

    if ( $subthing eq "history" ) {
        return $mongo->collection('History')->find({
            'target.type'   => "entity",
            'target.id'     => $id,
        });
    }
    
    die "Unsupported subthing request ($subthing) for Entity";

}

override get_subthing => sub {
    my $self        = shift;
    my $thing       = shift;
    my $id          = shift;
    my $subthing    = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;

    $id += 0;

    if ( $subthing  eq "alert" or
         $subthing  eq "event" or
         $subthing  eq "intel" or
         $subthing  eq "incident" ) {
        my $timer   = $env->get_timer("getting links");
        my $col = $mongo->collection('Link');
        my $cur = $col->find({entity_id     => $id,
                              'target.type' => $subthing,});
        my @ids         = map { $_->{target}->{id} } $cur->all;
        my $subcursor   = $mongo->collection(ucfirst($subthing))->find({
            id  => { '$in' => \@ids }
        });
        &$timer;
        return $subcursor;
    }
    elsif ( $subthing eq "entity" ) {
        my $lc  = $mongo->collection('Link');
        my $cc  = $lc->get_links_by_target({
            id  => $id, type => 'entity'
        });
        my @lnk = map { $_->{id} } $cc->all;
        my $cur = $self->find({id => {'$in' => \@lnk}});
        return $cur;
    }
    elsif ( $subthing eq "entry" ) {
        my $col = $mongo->collection('Entry');
        my $cur = $col->get_entries_by_target({
            id  => $id,
            type    => 'entity',
        });
        return $cur;
    }
    elsif ( $subthing eq "file" ) {
        my $col = $mongo->collection('File');
        my $cur = $col->find({
            'entry_target.type' => 'entity',
            'entry_target.id'   => $id,
        });
        return $cur;
    }
    else {
        $log->error("unsupported subthing $subthing!");
    }
};

sub get_by_value {
    my $self    = shift;
    my $value   = shift;
    my $object  = $self->find_one({ value => $value });
    if ( defined $object ) {
        my $data = $object->data;
        unless (defined $data) {
            # enrichment failed at some point, let's try again
        }
    }
    return $object;
}

sub autocomplete {
    my $self    = shift;
    my $frag    = shift;
    my $cursor  = $self->find({
        value => /$frag/
    });
    my @records = map { {
        id  => $_->{id}, key => $_->{value}
    } } $cursor->all;
    return wantarray ? @records : \@records;
}

sub get_cidr_ipaddrs {
    my $self    = shift;
    my $mask    = shift;

    return $self->find({
        'data.binip'    => qr/^$mask/
    });
}


1;
