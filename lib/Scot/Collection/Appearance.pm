package Scot::Collection::Appearance;
use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';

sub create_from_handler {
    return {
        error   => "Direct creation of appearance record from Web API not supported",
    };
}

sub adjust_appearances {
    my $self    = shift;
    my $object  = shift;
    my $newset  = shift; # aref
    my $type    = shift; # tag or source # no plural
    my $log     = $self->env->log;

    my $objid   = $object->id;
    my $objtype = $object->get_collection_name;

    my %lookup  = ();
    foreach my $item (@$newset) {
        $lookup{$item}++;
    }

    my $cursor  = $self->find({
        type    => $type,
        'target.id'     => $objid,
        'target.type'   => $objtype,
    });

    my %removed= ();
    while ( my $appearance = $cursor->next ) {
        my $value   = $appearance->value;
        $log->debug("value $value was associated with $objtype $objid");
        if ( ! defined $lookup{$value}) {
            # remove appearance
            $log->debug("removing this appearance ".$appearance->id);
            $appearance->remove;
            $removed{$value}++;
        }
    }

    foreach my $value (keys %lookup) {
        if ( ! defined $removed{$value} ) {
            # this means value is a new value and an appearance should be added
            $log->debug("The $value is new, creating an appearance");
            $self->create({
                type    => $type,
                value   => $value,
                apid    => $self->lookup_value_id($value,$type),
                when    => $self->env->now,
                target  => {
                    id      => $objid,
                    type    => $objtype,
                }
            });
        }
    }
}

sub lookup_value_id {
    my $self    = shift;
    my $value   = shift;
    my $type    = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    my $object  = $mongo->collection(ucfirst($type))->find_one({
        value   => $value
    });

    if ( defined $object ) {
        $log->debug("object $type ".$object->id." exists");
        return $object->id;
    }
    $log->debug("object $value does not exist, creating");
    # create the tag/source
    $object = $mongo->collection(ucfirst($type))->create({
        value   => $value
    });

    return $object->id;
}


sub get_total_appearances {
    my $self    = shift;
    my $type    = shift;
    my $value   = shift;

    my $count  = $self->count({
        type    => $type,
        value   => $value,
    });

    return $count;
}

sub get_appearance_cursor {
    my $self    = shift;
    my $type    = shift;
    my $value   = shift;

    my $cursor  = $self->find({
        type    => $type,
        value   => $value,
    });

    return $cursor;
}


1;
