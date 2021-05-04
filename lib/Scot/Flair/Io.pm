package Scot::Flair::Io;

use Data::Dumper;
use Moose;

has env => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
);

sub get_object {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $mode    = $self->env->fetch_mode // 'mongo';

    return ($mode eq 'mongo') ? 
        $self->get_from_mongo($type, $id) :
        $self->get_via_api($type, $id);

}

sub get_from_mongo {
    my $self    = shift;
    my $colname = shift;
    my $id      = shift;

    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection(ucfirst($colname));

    my $object  = $col->find_iid($id);

    return $object;
}

sub get_via_api {
    my $self    = shift;
    my $colname = shift;
    my $id      = shift;
    my $uri     = "/scot/api/v2/$colname/$id";

    # TODO
    # get via the API
    # convert API return into object
    # return the object

}

sub get_alerts {
    my $self        = shift;
    my $alertgroup  = shift;
    my $agid        = $alertgroup->id;
    my $mode    = $self->env->fetch_mode // 'mongo';
    my @alerts  = ();

    if ( $mode eq "mongo" ) {
        my $col     = $self->env->mongo->collection('Alert');
        my $cursor  = $col->find({ alertgroup => $agid });
        return  $cursor;
    }
    # TODO API fetch json array
    # turn into a "cursor"
    # return that cursor;
}

sub update_entry {
    my $self    = shift;
    my $entry   = shift;
    my $results = shift;
    my $log     = $self->env->log;
    my $mode    = $self->env->fetch_mode // 'mongo';

    $log->debug("[$$] updating entry ".$entry->id);

    my $update = {
        body_plain  => $results->{text},
        body_flair  => $results->{flair},
    };

    if ( $mode eq "mongo" ) {
        $entry->update({
            '$set'  => $update
        });
        return;
    }
    # TODO API update
    $log->debug("need to implement api update");
}

sub update_entity {
    my $self    = shift;
    my $target  = shift;
    my $entity  = shift;
    my $log     = $self->env->log;
    my $mode    = $self->env->fetch_mode // 'mongo';

    $log->debug("Updating Entity ",{filter=>\&Dumper, value=>$entity});
    $log->trace("target is ", {filter=>\&Dumper, value=>$target});

    if ( $mode eq "mongo" ) {
        my $mongo   = $self->env->mongo;
        my $col     = $mongo->collection('Entity');
        $col->update_entity($target, $entity);
        return;
    }
}

sub get_single_word_regexes {
    my $self    = shift;
    my $query   = { options => { multiword => "no" } };
    my @ets     = $self->get_entity_types($query);
    return wantarray ? @ets : \@ets;
}


sub get_multi_word_regexes {
    my $self    = shift;
    my $query   = { options => { multiword => "yes" } };
    my @ets     = $self->get_entity_types($query);
    return wantarray ? @ets : \@ets;
}
    
sub get_entity_types {
    my $self    = shift;
    my $query   = shift;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Entitytype');
    my $cursor  = $col->find($query);
    my @etypes  = ();

    while (my $et = $cursor->next) {
        push @etypes, {
            type    => $et->value,
            regex   => $et->match,
            order   => $et->order,
            options => $et->options,
        };
    }
    return wantarray ? @etypes : \@etypes;
}

sub update_entities {
    my $self    = shift;
    my $target  = shift;
    my $results = shift;
    my $mongo   = $self->env->mongo;
    my $ecol    = $mongo->collection('Entity');
    my $log     = $self->env->log;

    $log->debug("updating entities");

    my $entities    = $results->{entities};

    foreach my $entity_href (@$entities) {
        my $query   = { 
            type => $entity_href->{type}, 
            value => $entity_href->{value} };
        my $status = $ecol->update_entity($target, $entity_href);
    }

}


    

1;
