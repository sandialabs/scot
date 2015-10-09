package Scot::Collection::Entry;

use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';

with    qw(
    Scot::Role::GetTargeted
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

sub create_from_api {
    my $self    = shift;
    my $request = shift;

    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    $log->trace("Custom create in Scot::Collection::Entry");

    my $json    = $request->{request}->{json};

    my $target_type = $json->{target_type};
    my $target_id   = $json->{target_id};

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

    $json->{targets}    = [ {
        target_id   => $target_id,
        target_type => $target_type,
    } ];

    delete $json->{target_id};
    delete $json->{target_type};

    my $entry_collection    = $mongo->collection("Entry");
    my $entity_collection   = $mongo->collection("Entity");

    $request->{task} = $self->validate_task($request);

    unless ( $request->{readgroups} ) {
        $json->{readgroups} = $env->default_groups->{read};
    }
    unless ( $request->{modifygroups} ) {
        $json->{modifygroups} = $env->default_groups->{modify};
    }

    $log->debug("Creating entry with: ", { filter=>\&Dumper, value => $json});

    my $entry_obj   = $entry_collection->create($json);

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
    my $href    = shift;
    my $json    = $href->{request}->{json};

    unless ( defined $json->{task} ) {
        # if task isn't set that is ok and valid
        return {};
    }

    # however, if it is set, we need to make sure it has 
    # { when => x, who => user, status => y }

    unless ( defined $json->{task}->{when} ) {
        $href->{when} = $self->env->now();
    }

    unless ( defined $json->{task}->{who} ) {
        $href->{who}    = $href->{user};
    }
    unless ( defined $json->{task}->{status} ) {
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
