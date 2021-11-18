package Scot::Collection::Entity;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;
use Net::IP;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
    Scot::Role::GetTargeted
);

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

sub update_entity {
    my $self    = shift;
    my $target  = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    my $mongo   = $self->meerkat;

    $log->trace("updatiing entity",{filter=>\&Dumper, value=>$href});
    $log->trace("Target is ".ref($target)." ".$target->id);

    my $value   = $href->{value};
    my $type    = $href->{type};

    my $entity = $self->find_one({
        value   => $value,
        type    => $type,
    });

    if ( ! defined $entity or ref($entity) ne "Scot::Model::Entity") {
        # create link
        $log->debug("Creating new $type entity $value");
        $entity = $self->create({
            value   => $value,
            type    => $type,
        });
    }
    $self->create_entity_links($entity, $target);
    return 1;
}

sub update_entities {
    my $self    = shift;
    my $target  = shift;    # Scot::Model Object
    my $earef   = shift;    # array of hrefs that hold entityinfo

    my $env     = $self->env;
    my $log     = $self->log;
    my $mongo   = $self->meerkat;   
    # no done async
    # my $enrichments = $env->enrichments;

    my $thash = $target->as_hash;
    $self->log->debug("updating entities on target ",
                            { filter =>\&Dumper, value => $thash});

    $log->debug("earef is ",{filter=>\&Dumper, value=>$earef});

    my $type    = $target->get_collection_name;
    my $id      = $target->id;
    my $linkcol = $mongo->collection('Link');

    $log->debug("[$type $id] Updating associated entities");
    $log->debug("[$type $id] ", {filter=>\&Dumper, value=>$earef});
    
    my @created_ids = ();
    my @updated_ids = ();
    my %seen        = ();
    my @entity_ids  = ();
    ENTITY:
    foreach my $entity (@$earef) {

        my $value   = $entity->{value};
        my $etype   = $entity->{type};

        if ( defined $seen{$etype.$value} ) {
            next ENTITY;
        }

        $seen{$etype.$value}++;

        my $entity  = $self->find_one({
            value   => $value,
            type    => $etype
        });

        if ($entity) {
            my $entity_status   = $entity->status;
            if ( $entity_status eq "untracked" ) {
                next ENTITY;
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
        $self->create_entity_links($entity, $target);
        push @entity_ids, $entity->id; 
    }
    return \@created_ids, \@updated_ids, \@entity_ids;
}

sub merge_entity_data {
    my $self    = shift;
    my $old     = shift;
    my $new     = shift;
    my $merged  = {};

    # old data inserted first

    foreach my $key (keys %{$old}) {
        $merged->{$key} = $old->{$key};
    }

    # new data is added or overwrites old

    foreach my $key (keys %{$new}) {
        $merged->{$key} = $new->{$key};
    }

    return $merged;
}

sub upsert_link {
    my $self    = shift;
    my $entity  = shift; # object
    my $target  = shift; # href

    $self->log->trace("upsert link: Entity ".$entity->id." to ".
        $target->{type}." ".$target->{id});

    my $linkcol = $self->meerkat->collection('Link');
    my $v1 = {
        id     => $target->{id},
        type   => $target->{type},
    };

    if ( $linkcol->link_exists($entity,$v1) ) {
        $self->log->debug("Entity already linked to target");
        return;
    }

    $self->log->trace("Link does not exist, creating...");

    my $linkobj    = $linkcol->link_objects(
        $entity, { 
            type    => $target->{type},
            id      => $target->{id}, 
        }
    );
    return $linkobj;
}

sub create_entity_links {
    my $self    = shift;
    my $entity  = shift; # object
    my $target  = shift; # object
    my $log = $self->log;

    $log->trace("collection: create_entity_links");
    $log->trace("Entity ".$entity->id." to Target ".$target->id);

    $self->upsert_link($entity, {
        id      => $target->id,
        type    => $target->get_collection_name,
    });

    if ( $target->get_collection_name eq "entry" ) {
        $log->debug("upserting entries target");
        my $additional_link = $self->upsert_link(
            $entity, {
                type    => $target->target->{type},
                id      => $target->target->{id},
            }
        );
    }
    if ( $target->get_collection_name eq "alert" ) {
        my $additional_link = $self->upsert_link(
            $entity, {
                type    => "alertgroup",
                id      => $target->alertgroup,
            }
        );
    }


    if ( $entity->type  eq "cidr" ) {
        # find and create links to ipaddresses in that range
        my $value   = $entity->value;
        my ($cidrbase,$cidrmask) = split(/\//,$value);
        if ( $cidrmask > 0 ) {
            $log->debug("Finding IPaddrs that are in $cidrbase/$cidrmask");
            my $ipobj   = Net::IP->new($value);
            if ( ! defined $ipobj ) {
                $log->error("Failed to create Net::IP object from $value!");
                return;
            }
            my $mask    = substr($ipobj->binip, 0, $cidrmask);
            my @records = $self->get_cidr_ipaddrs($mask);
            $log->debug("Found ".scalar(@records)." ipaddresses");
            foreach my $rec (@records) {
                $log->debug("upserting entity ".$rec->{id});
                $self->upsert_link($entity, {
                    id      => $rec->{id},
                    type    => "entity",
                });
            }
        }
        else {
            $log->debug("cidr mask is 0.  Skipping");
        }
    }
}

sub api_subthing {
    my $self    = shift;
    my $req     = shift;
    my $thing   = $req->{collection};
    my $id      = $req->{id} + 0;
    my $subthing= $req->{subthing};
    my $env     = $self->env;
    my $mongo   = $self->meerkat;
    my $log     = $self->log;

    if ( $subthing  eq "alert" or
         $subthing  eq "event" or
         $subthing  eq "dispatch" or
         $subthing  eq "intel" or
         $subthing  eq "product" or
         $subthing  eq "guide" or 
         $subthing  eq "signature" or
         $subthing  eq "incident" ) {
        return $mongo->collection('Link')
                     ->get_linked_objects_cursor(
                        { id => $id, type => 'entity' },
                        $subthing);
    }

    if ( $subthing eq "entity" ) {
        # entities linking to entities, oh my, what could go wrong
        return $mongo->collection('Link')
                     ->get_linked_objects_cursor(
                        { id => $id, type => 'entity' },
                        'entity' );
    }
    if ( $subthing eq "link" ) {
        return $mongo->collection('Link')
                    ->get_links_by_target({
                        id      => $id,
                        type    => $thing,
                    });
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
    my $mongo   = $self->meerkat;
    my @records = ();

    my $cursor = $self->find({
        'data.binip'    => qr/^$mask/
    });

    while ( my $entity = $cursor->next ) {
        my $linkcursor = $mongo->collection('Link')->
            get_object_links_of_type($entity, undef);

        push my @final, map { $_->{vertices} } $linkcursor->all;
        my $href = {
            id      => $entity->id,
            value   => $entity->value,
            targets => \@final,
        };
        push @records, $href;
    }
    return wantarray ? @records : \@records;

}

sub api_create {
    my $self    = shift;
    my $req     = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    my $mongo   = $self->meerkat;
    my $user    = $req->{user};
    my $json    = $req->{request}->{json};
    
    $log->debug("req is ",{filter=> \&Dumper, value => $req});

    return $self->create($json);
}


1;
