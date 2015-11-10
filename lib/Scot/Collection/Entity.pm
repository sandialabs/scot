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
                target_type => $thing,
                target_id   => $id,
            },
        },
    });
    my $count   = $cursor->count;
    return $cursor;
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

    $log->trace("Updating Entity with target $type $id info");

    my $histcol = $mongo->collection('History');

    foreach my $entity (@$entities) {
        $log->trace("working on entity ", { filter =>\&Dumper, value => $entity});
        my $value   = $entity->{value};
        my $type    = $entity->{type};
        my $eobj    = $self->find_one({value => $value, type => $type});

        my $thref   = {
            target_type => $type,
            target_id   => $id,
        };

        if ( defined $eobj   ) {
            if ( $eobj->update_push( targets => $thref ) ) {
                $log->trace("Updated Entity $value");
                $histcol->add_history_entry({
                    who     => "api",
                    what    => "appeared in $type : $id",
                    when    => $target->when // $target->created,
                    targets => [ { target_id => $eobj->id, target_type => "entity" } ],
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
                    target_type => 'alertgroup', target_id => $target->alertgroup 
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
                        target_id   => $eobj->id,
                        target_type => "entity",
                    }],
                    when    => $target->when // $target->created,
                    what    => "entity created",
                    who     => "flair",
                });
            }
        }
    }
}



# use get_targeted instead (same code)
sub get_entities {
    my $self    = shift;
    my %params  = @_;

    my $cursor  = $self->find({
        targets => {
            target_id   => $params{target_id},
            target_type => $params{target_type},
        }
    });
    return $cursor;
}


1;
