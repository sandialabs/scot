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

    my $target_type = delete $json->{target_type};
    my $target_id   = delete $json->{target_id};

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

    my $entry_collection    = $mongo->collection("Entry");
    my $entity_collection   = $mongo->collection("Entity");

    $request->{task} = $self->validate_task($request);

    unless ( $request->{readgroups} ) {
        $json->{groups}->{read} = $env->default_groups->{read};
    }
    unless ( $request->{modifygroups} ) {
        $json->{groups}->{modify} = $env->default_groups->{modify};
    }

    $log->debug("Creating entry with: ", { filter=>\&Dumper, value => $json});

    my $entry_obj   = $entry_collection->create($json);

    my $linkcol = $mongo->collection('Link');
    my $linkobj = $linkcol->create_link({
        type   => "entry",
        id     => $entry_obj->id,
    },{
        id      => $target_id,
        type    => $target_type,
    });

    return $entry_obj;

}

sub create_via_alert_promotion {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $mongo   = $self->meerkat;
    my $col     = $mongo->collection('Entry');

    die "implement this!";

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
        type => $thing,
        id   => $id,
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

sub create_file_entry {
    my $self    = shift;
    my $fileobj = shift;
    my $entryid = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $entryid += 0;

    my $fid     = $fileobj->id;
    my $htmlsrc = <<EOF;

<div class="fileinfo">
    <table>
        <tr>
            <th>File Id</th>%d</td>
            <th>Filename</th><td>%s</td>
            <th>Size</th><td>%s</td>
            <th>md5</th><td>%s</td>
            <th>sha1</th><td>%s</td>
            <th>sha256</th><td>%s<d>
            <th>notes</th><td>%s</td>
    </table>
    <a href="/scot/file/%d?download=1">
        Download
    </a>
</div>
EOF
    my $html = sprintf(
        $htmlsrc,
        $fileobj->id,
        $fileobj->filename,
        $fileobj->size,
        $fileobj->md5,
        $fileobj->sha1,
        $fileobj->sha256,
        $fileobj->notes,
        $fileobj->id);

    my $linkcol = $self->env->mongo->collection('Link');
    my $newentry;

    # TODO: potential problem here that needs more thought
    #  groups is being set to default_groups and probably should inherit from parent
    # entry_id or target's permissions

    my $href    = {
        body    => $html,
        parent  => $entryid,
        groups  => $env->default_groups,
    };

    $log->debug("Creating Entry with ", {filter=>\&Dumper, value => $href});

#    try {
        $newentry = $self->create($href);
#    }
#    catch {
#        $log->error("Failed to create Entry!: $_");
#    };

    return $newentry;
}


1;
