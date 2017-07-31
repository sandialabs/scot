package Scot::Collection::Link;

use lib '../../../lib';
use Data::Dumper;
use Try::Tiny;
use Moose 2;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
);

sub create_from_api {
    my $self    = shift;
    return $self->create_link(@_);
}

# link creation or update
sub create_link {
    my $self    = shift;
    my $entity  = shift; # expecting $entity object or HREF { id =>x, value=>y }
    my $target  = shift; # href { id => x, type => y }
    my $when    = shift // $self->env->now();
    my $eid;
    my $value;

    if ( ref($entity) eq 'Scot::Model::Entity') {
        $eid    = $entity->id;
        $value  = $entity->value;
    }
    elsif ( ref($entity) eq "HASH" ) {
        $eid    = $entity->{id};
        $value  = $entity->{value};
    }
    else {
        $self->env->log->error("param 1 (entity) invalid!");
        return undef;
    }

    if ( ref($target) ne "HASH" ) {
        $self->env->log->error("param 2 (target) is not HashRef!");
        return undef;
    }

    unless ( $target->{id} or $target->{type} ) {
        $self->env->log->error("param 2 (target) is not valid!");
        return undef;
    }

    my $link;
    try {
        $link    = $self->create({
            when        => $when,
            entity_id   => $eid,
            value       => $value,
            target      => $target,
        });
    }
    catch {
        $self->env->log->error("Failed to create Link!: ", $_);
    };

    return $link;
}

sub get_links_by_value {
    my $self    = shift;
    my $value   = shift;
    my $cursor  = $self->find({value => $value});
    return $cursor;
}

sub get_links_by_entity_id {
    my $self    = shift;
    my $id      = shift;
    my $cursor  = $self->find({ entity_id => $id });
    return $cursor;
}

sub get_links_by_target {
    my $self    = shift;
    my $target  = shift;
    my $id      = $target->{id};
    my $type    = $target->{type};

    $self->env->log->debug("Finding Links to $type $id");
    my $cursor = $self->find({
        'target.type'   => $type,
        'target.id'     => $id + 0,
    });
    # weird unpredictable results
    #my $cursor  = $self->find({
    #    target  => {
    #        id     => $id,
    #        type   => $type,
    #    }
    #});
    $self->env->log->debug("found ".$cursor->count." links");
    return $cursor;
}

sub get_total_appearances {
    my $self    = shift;
    my $entity  = shift;
    my $cursor  = $self->find({ entity_id => $entity->id });

    return $cursor->count;
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

    my $cursor  = $self->find({
        'entity_id'   => $entity->id,
        'target.type' => {
            # '$in'  => [ 'alert', 'incident', 'intel', 'event' ]
            '$nin'  => [ 'alertgroup', 'entry' ]
        }
    });

    if ( $cursor->count > 1000 ) {
        # return a quicker esitmate
        return $cursor->count;
    }

    my %seen;
    while (my $link = $cursor->next) {
        my $key = $link->target->{type} . $link->target->{id};
        $seen{$key}++;
    }
    return scalar(keys %seen);
}

sub get_display_count_buggy_but_fast {
    my $self    = shift;
    my $entity  = shift;
    my $collection  = $self->collection_name;
    my $log     = $self->env->log;
    my %command;
    my $tie = tie(%command, "Tie::IxHash");
    %command = (
        'distinct'  => 'link',
        'key'       => 'target.id',
        'query'     => { 
            value => $entity->value,
            'target.type'   => {
                '$in'   => [ 'alert', 'event', 'intel', 'incident' ]
            }
        },
    );
    $self->env->log->debug("display count command is ",{filter=>\&Dumper, value=>\%command});

    my $mongo   = $self->meerkat;
    my $result  = $self->_try_mongo_op(
        get_distinct    => sub {
            my $dbn  = $mongo->database_name;
            my $db   = $mongo->_mongo_database($dbn);
            my $job  = $db->run_command(\%command);
            # $self->env->log->debug("job is ",{filter=>\&Dumper, value=>$job});
            return $job->{values};
        }
    );
    $self->env->log->debug("got result: ",{filter=>\&Dumper, value=>$result});
    unless (defined $result) {
        return 0;
    }
    return scalar(@$result);
}

sub get_degree {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $cursor  = $self->get_links_by_target({
        type    => $type,
        id      => $id
    });
    # TODO: implement the db.link.distinct("value") in meerkat
    my %seen    = ();
    
    while ( my $link = $cursor->next ) {
        $seen{$link->value}++;
    }
    return scalar(keys %seen);
}


1;
