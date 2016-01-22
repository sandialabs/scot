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

sub create_from_handler {
    return {
        error   => "Direct creation of Entities from Web API not supported",
    };
}

sub get_entity_data_for {
    my $self    = shift;
    my $thing   = shift;
    my $id      = shift;
    $id         +=0;

    my $cursor  = $self->find({
        targets => {
            '$elemMatch' => {
                type => $thing,
                id   => $id,
            },
        },
    });
    my $count   = $cursor->count;
    return $cursor;
}

sub update_entities {
    my $self    = shift;
    my $target  = shift;    # Scot::Model Object
    my $earef   = shift;    # array of hrefs that hold entityinfo

    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $type    = $target->get_collection_name;
    my $id      = $target->id;
    my $linkcol = $mongo->collection('Link');

    $log->trace("[$type $id] Updating associated entities");
    
    # find entity or create it.

    foreach my $entity (@$earef) {
        my @command    = (
            findAndModify   => "entity",
            query           => { 
                value   => $entity->{value}, 
                type    => $entity->{type},
            },
            update          => {
                '$setOnInsert'  => {
                    value   => $entity->{value},
                    type    => $entity->{type},
                }
            },
            new     => 1,
            upsert  => 1,
        );

        my $return = $self->_try_mongo_op(
            find_or_create => sub {
                my $dbname  = $self->meerkat->database_name;
                my $db      = $self->meerkat->_mongo_database($dbname);
                my $job     = $db->run_command(\@command);
                return $job;
            }
        );

        $log->debug("FindAndModify returned: ",{ filter =>\&Dumper, value => $return });

        my $entity_id    = $return->{id};

        my $link    = $linkcol->add_link({
            item_type   => "entity",
            item_id     => $entity_id,
            when        => $env->now(),
            target_type => $type,
            target_id   => $id,
        });
    }
}




sub update_entities_from_target {
    my $self        = shift;
    my $target      = shift;
    my $entities    = shift;
    my $env         = $self->env;
    my $log         = $self->env->log;
    my $mongo       = $env->mongo;

    my $type        = $target->get_collection_name; # entry or alert

    unless ($type eq "entry" or $type eq "alert") {
        $log->warn("Type of $type is not supported as target");
    }

    my $id  = $target->id;
    my $thref   = {
        type => $type,
        id   => $id,
    };

    my @auxtargets = ();
    push @auxtargets, $thref;

    if ( $type eq "entry" ) {
        # add the type that the entry points to as well
        @auxtargets = @{ $target->targets };
    }

    $log->trace("Updating Entity with target $type $id info");

    my $histcol = $mongo->collection('History');
    my %seen    = ();

    foreach my $entity (@$entities) {
        # $log->trace("working on entity ", { filter =>\&Dumper, value => $entity});
        my $value   = $entity->{value};
        my $etype    = $entity->{type};
        my $eobj    = $self->find_one({value => $value, type => $etype});

        next if $seen{$value}{$etype};
    
        if ( defined $eobj   ) {
            if ( $eobj->update({
                    '$addToSet' => {targets => {'$each' => \@auxtargets }}
                }) ) {
                $log->trace("Updated Entity $value");
                $histcol->add_history_entry({
                    who     => "api",
                    what    => "appeared in $type : $id",
                    when    => $target->when // $target->created,
                    targets => [ { id => $eobj->id, type => "entity" } ],
                }); 
            }
            else {
                $log->error("Failed to update Entitity $value (".$eobj->id.")");
                $log->error("Target was ", { filter => \&Dumper, value => $thref });
            }
        }
        else {
            $log->trace("Entity $value is NEW!");
            my $timestamp   = $env->now();
            my $ehref   = {
                value   => $value,
                type    => $type,
                targets => [ $thref ],
                when    => [ $timestamp ],
                classes => [],
            };
            if ( $type  eq "alert" ) {
                push @{$ehref->{targets}},{ 
                    type => 'alertgroup', id => $target->alertgroup 
                };
            }

            $eobj   = $self->create($ehref);

            unless ( $eobj ) {
                $log->error("Failed to create entity with ",
                            { filter => \&Dumper, value => $ehref } );
            }
            else {
                $log->trace("Created new entity $value");
                $env->amq->send_amq_notification("creation", $eobj, "flair");
                $histcol->add_history_entry({
                    targets => [ {
                        id   => $eobj->id,
                        type => "entity",
                    }],
                    when    => $target->when // $target->created,
                    what    => "entity created",
                    who     => "flair",
                });
            }
        }
        $seen{$value}{$etype}++;
    }
}



# use get_targeted instead (same code)
sub get_entities {
    my $self    = shift;
    my %params  = @_;

    my $cursor  = $self->find({
        targets => {
            id   => $params{target_id},
            type => $params{target_type},
        }
    });
    return $cursor;
}


1;
