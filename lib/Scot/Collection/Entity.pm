package Scot::Collection::Entity;
use lib '../../../lib';
use Moose 2;
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

sub update_entities_from_entry {
    my $self        = shift;
    my $entry_obj   = shift;
    my $ent_aref    = shift; # [ { type=>t, value=>v },... ]

    my $this_type   = "entry";
    my $this_id     = $entry_obj->id;
    my $target_type = $entry_obj->target_type;
    my $target_id   = $entry_obj->target_id;
    my $timestamp   = $entry_obj->updated;

    ENTITY:
    foreach my $ent_href (@{$ent_aref}) {
        my $value   = $ent_href->{value};
        my $type    = $ent_href->{type};
        my $entity  = $self->find_one({value => $value, type => $type});

        if ( defined $entity ) {
            $entity->update_add( targets => { 
                target_type => $target_type,
                target_id   => $target_id,
            });
            $entity->update_add( targets => {
                target_type => $this_type,
                target_id   => $this_id,
            });
            $entity->update_add( occurred   => $timestamp);
            next ENTITY;
        }
        $entity = $self->create({
            value   => $value,
            type    => $type,
            targets => [
                {target_type => $target_type, target_id => $target_id}
            ],
            when    => [ $timestamp ],
            classes => [],
            occurred => [ $timestamp ],
        });
    }
}

sub update_entities_from_alert {
    my $self        = shift;
    my $alertobj    = shift; 
    my $ent_aref    = shift; # [ {type=>t,value=>v}, ... ]

    my $alertgroup  = $alertobj->alertgroup;
    my $id          = $alertobj->id;
    my $timestamp   = $alertobj->updated;

    my $mongo   = $self->meerkat;
    my $col     = $mongo->collection("Entity");

    ENTITY:
    foreach my $ent_href ( @{$ent_aref} ) {

        my $value   = $ent_href->{value};
        my $type    = $ent_href->{type};
        my $entobj  = $col->find_one({value => $value, type => $type});

        if ( defined $entobj ) {
            $entobj->update_add( targets => { target_type   => "alertgroup",
                                            target_id     => $alertgroup } );
            $entobj->update_add( targets => { target_type   => "alert",
                                            target_id     => $id });
            $entobj->update_add( when    => $timestamp );
            next ENTIIY;
        }

        $entobj = $col->create({
            value   => $value,
            type    => $type,
            targets => [
                {target_type => "alertgroup", target_id => $alertgroup},
                {target_type => "alert",      target_id => $id},
            ],
            when    => [ $timestamp ],
            classes => [],
        });
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
