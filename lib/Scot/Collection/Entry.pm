package Scot::Collection::Entry;
use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetTargeted
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

sub create_from_handler {
    my $self    = shift;
    my $handler = shift;
    my $env     = $handler->env;
    my $log     = $env->log;

    $log->trace("Custom create in Scot::Collection::Entry");

    my $build_href  = $handler->get_request_params->{params};
    my $target_type = $build_href->{target_type};
    my $target_id   = $build_href->{target_id};

    unless ( defined $target_type ) {
        $log->error("Error: Must provide a target type");
        return {
            error_msg   => "Entries must have target_type defined",
        };
    }

    unless ( defined $target_id ) {
        $log->error("Error: Must provide a target id");
        return {
            error_msg   => "Entries must have target_id defined",
        };
    }

    my $entry_collection    = $handler->env->mongo->collection("Entry");
    my $entity_collection   = $handler->env->mongo->collection("Entity");

    $build_href->{task} = $self->validate_task($handler, $build_href->{task});

    unless ( $build_href->{readgroups} ) {
        $build_href->{readgroups} = $env->default_groups->{readgroups};
    }
    unless ( $build_href->{modifygroups} ) {
        $build_href->{modifygroups} = $env->default_groups->{modifygroups};
    }

    my $entitydb = $env->entity_extractor->process_entry($build_href);

    $build_href->{body_flaired}     = $entitydb->{flair};
    $build_href->{body_plaintext}   = $entitydb->{text};
    my $ent_aref                    = $entitydb->{entities};

    my $entry_obj   = $entry_collection->create($build_href);

    $entity_collection->update_entities_from_entry($entry_obj, $ent_aref);

    return $entry_obj;

}

sub create_via_alert_promotion {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $mongo   = $self->meerkat;
    my $col     = $mongo->collection('Entry');



}



sub validate_task {
    my $self    = shift;
    my $handler = shift;
    my $href    = shift;

    unless ( defined $href ) {
        # if task isn't set that is ok and valid
        return {};
    }

    # however, if it is set, we need to make sure it has 
    # { when => x, who => user, status => y }

    unless ( defined $href->{when} ) {
        $href->{when} = $handler->env->now();
    }

    unless ( defined $href->{who} ) {
        $href->{who}    = $handler->session('user');
    }
    unless ( defined $href->{status} ) {
        $href->{status} = "open";
    }
    return $href;
}


sub get_entries {
    my $self    = shift;
    my %params  = @_;
    my $id      = $params{target_id};
    my $thing   = $params{target_type};
    $id         +=0;

    my $cursor  = $self->find({
        target_type => $thing,
        target_id   => $id,
    });
    return $cursor;
}

sub get_tasks   {
    my $self    = shift;
    my $cursor  = $self->find({
        'task.status'   => { '$exists' => 1}
    });
    return $cursor;
}


1;
