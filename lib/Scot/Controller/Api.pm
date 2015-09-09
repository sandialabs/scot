package Scot::Controller::Api;


=head1 Name

Scot::Controller::Api

=head1 Description

Perform the CRUD operations based on JSON input and provide JSON output

=cut

use Data::Dumper;
use Try::Tiny;
use strict;
use warnings;
use base 'Mojolicious::Controller';

=head1 Routes

=over 4

=item I<CREATE> B<POST /scot/api/v2/:thing>

=cut

sub create {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $user    = $self->session('user');

    $log->trace("Handler is processing a POST (create) from $user");

    my $thing   = $self->stash('thing');
    my $colname = ucfirst($thing);

    unless ($colname) {
        $log->error("No collection Name provided!");
        $self->do_error(400, { error_msg => "missing collection" });
        return;
    }
    
    my $collection;

    $log->trace("Getting Collection for $colname");

    try {
        $collection  = $mongo->collection($colname);
    }
    catch {
        $self->do_error(400, {
            error_msg   => "Invalid Collection: $colname"
        });
        return;
    };

    $log->debug("collection is ".ref($collection));

    unless ( defined $collection ) {
        $self->do_error(400,{
            error_msg => "Collection Error: $colname"
        });
        return;
    }

    my $object  = $collection->create_from_api($self);

    unless ( defined $object ) {
        $self->do_error(400, {
            error_msg => "Failed to Create $colname"
        });
        return;
    }

    if ( ref($object) eq "HASH" ) {
        # a specific error condition is in the object hashref
        $self->do_error(400, $object);
        return;
    }

    $env->amq->send_amq_notification("creation", $object, $user);

    $self->do_render({
        action  => 'post',
        thing   => $colname,
        id      => $object->id,
        status  => 'ok',
    });


    $self->audit("create_thing", {
        thing   => $self->get_object_collection($object),
        id      => $object->id,
    });
}

=item B<GET /scot/api/v2/:thing>

=pod

@api {post} /scot/api/v2/:thing
@apiName Get Lis of :thing
@apiGroup CRUD
@apiDescription Retrieve a set of things
@apiParam {String} thing The "alert", "event", "incident", "intel", etc. you wish to retrieve

@apiExample Example Usage
    curl https://scotserver/scot/api/v2/alert

@apiSuccessExample {json} Success-Response:
    HTTP/1.1 200 OK
    {
        "records":  [
            { key1: value1, ..., keyx: valuex },
            ...
        ],
        "queryRecordCount": 25,
        "totalRecordCount": 102323
    }

=cut

sub get_many {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $user    = $self->session('user');

    $log->trace("Handler is processing a GET MANY request from $user");

    my $req_href    = $self->get_request_params;
    my $col_name    = $req_href->{collection};
    my $collection;
    my $match_ref;

    try {
        $collection  = $mongo->collection(ucfirst($col_name));
    }
    catch {
        $log->error("Failed to get collection $col_name");
        $self->do_error(400, { error_msg => "missing or invalid collection"});
        return;
    };

    unless (defined $collection) {
        $self->do_error(400, {
            error_msg => "No collection matching $col_name" });
        return;
    }

    $match_ref   = $self->build_match_ref($req_href);

    my $cursor      = $collection->find($match_ref);
    my $total       = $cursor->count;

    $log->trace("got $total matches");

    unless (defined $cursor) {
        $self->nothing_matching_error($match_ref);
        return;
    }
        
    if ( my $sort_opts = $self->build_sort_opts($req_href) ) {
        $cursor->sort($sort_opts);
        # $cursor->sort({name=>1});
    }
    else {
        $cursor->sort({id => -1});
    }

    if ( my $limit  = $self->build_limit($req_href) ) {
        $cursor->limit($limit);
    }
    else {
        $cursor->limit(50);
    }

    if ( my $offset = $self->build_offset($req_href) ) {
        $cursor->skip($offset);
    }

    # my @things = map { $self->mypack($_) } $cursor->all;
    my @things = $cursor->all;

    $self->do_render({
        records             => \@things,
        queryRecordCount    => $cursor->count,
        totalRecordCount    => $total
    });

    $self->audit("get_many", $req_href);
}

# this was a workaround for a bug in Meerkat
#sub mypack {
#    my $self    = shift;
#    my $thing   = shift;
#    return $thing->pack if ( ref($thing) =~ /Scot::Model/ );
#    return $thing;
#}

=item B<GET /scot/api/v2/:thing/:id>

=pod

@api {post} /scot/api/v2/:thing/:id
@apiName Get One of :thing
@apiGroup CRUD
@apiDescription Retrieve a thing
@apiParam {String} thing The "alert", "event", "incident", "intel", etc. you wish to retrieve

@apiExample Example Usage
    curl https://scotserver/scot/api/v2/alert/123

@apiSuccessExample {json} Success-Response:
    HTTP/1.1 200 OK
    {
        key1: value1,
        ...
    }

=cut

sub get_one {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $user    = $self->session('user');

    $log->trace("Handler is processing a GET ONE request");

    my $req_href    = $self->get_request_params;
    my $id          = $req_href->{id} + 0;
    my $col_name    = $req_href->{collection};

    unless ( $self->id_is_valid($id) ) {
        $self->do_error(400, {
            error_msg   => "Invalid integer id: $id"
        });
        return;
    }

    my $collection;

    try {
        $collection  = $mongo->collection(ucfirst($col_name));
    }
    catch {
        $log->error("Failed to get Collection $col_name");
        $self->do_error(400, {error_msg => "collection error"});
        return;
    };

    unless ( defined $collection ) {
        $self->do_error(400, { 
            error_msg => "No collection matching $col_name"
        });
        return;
    }

    my $object  = $collection->find_iid($id);

    unless ( defined $object ) {
        $log->error("No matching Object for $col_name : $id");
        $self->do_error(404, {
            error_msg   => "No matching object $col_name: $id"
        });
        return;
    }

    if ( $object->meta->does_role("Vast::Role::Permittable") ) {
        my $users_groups    = $self->session('groups');
        unless ( $object->is_readable($users_groups) ) {
            $self->read_not_permitted_error;
            return;
        }
    }

    if ( $object->meta->does_role("Vast::Role::Views") ) {
        $object->increment_views(1);
    }

    my $data_href   = {};
    if ( $req_href->{fields} and 
         $object->meta->does_role("Vast::Role::Hashable")) {
        $data_href  = $object->as_hash($req_href->{fields});
    }
    else {
        $data_href  = $object->as_hash;
    }

    $self->do_render($data_href);

    if ( $object->meta->does_role("Scot::Role::Views") ) {
        $object->increment_views;
    }

    $self->audit("get_one", $req_href);
}

=item B<GET /scot/api/v2/:thing/:id/:subthing>

=pod

@api {post} /scot/api/v2/:thing/:id/:subthing
@apiName Get related information
@apiGroup CRUD
@apiDescription Retrieve subthings related to the thing
@apiParam {String} thing The "alert", "event", "incident", "intel", etc. you wish to retrieve

@apiExample Example Usage
    curl https://scotserver/scot/api/v2/event/123/entry

@apiSuccessExample {json} Success-Response:
    HTTP/1.1 200 OK
    {
        [
            { key1: value1, ... },
            ...
        ]
    }

=cut

sub get_subthing {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    $log->trace("Processing a GET subthing request");

    my $req_href    = $self->get_request_params;
    my $id          = $req_href->{id};
    my $thing       = $req_href->{collection};
    my $subthing    = $req_href->{subthing};
    my $collection  = $mongo->collection(ucfirst($thing));
    my $cursor      = $collection->get_subthing($thing, $id, $subthing);

    unless ( defined $cursor ) {
        $log->error("No subthing data");
        $self->do_error(404, {
            error_msg   => "No $subthing(s) for object $thing: $id"
        });
        return;
    }

    my @things;
    if ( $subthing eq "entry" ) {
        @things = $self->thread_entries($cursor);
    }
    else {
        # @things = map { $self->mypack($_) } $cursor->all;
        @things = $cursor->all;
    }

    $self->do_render({
        records => \@things,
        queryRecordCount => scalar(@things),
        totalRecordCount => scalar(@things),
    });
    $self->audit("get_subthing", $req_href);
}

=item B<PUT /scot/api/v2/:thing/:id>

=pod

@api {post} /scot/api/v2/:thing/:id
@apiName Updated thing
@apiGroup CRUD
@apiDescription update thing 
@apiParam {String} thing The "alert", "event", "incident", "intel", etc. you wish to retrieve

@apiExample Example Usage
    curl https://scotserver/scot/api/v2/event/123 -d '{"key1": "value1", ...}'

@apiSuccessExample {json} Success-Response:
    HTTP/1.1 200 OK
    {
        id : 123,
        status : "successfully updated",
    }

=cut

sub update {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $user    = $self->session('user');

    $log->trace("API is processing a PUT update request from $user");

    my $req_href    = $self->get_request_params;
    my $id          = $req_href->{id};
    my $col_name    = $req_href->{collection};

    unless ( $self->id_is_valid($id) ) {
        $self->do_error(400, {
            error_msg   => "Invalid integer id: $id"
        });
        return;
    }

    my $collection;

    try {
        $collection  = $mongo->collection(ucfirst($col_name));
    }
    catch {
        $log->error("Weird collection error dude");
        $self->do_error(400, {
            error_msg   => "collection definition failure"
        });
        return;
    };

    unless ( defined $collection ) {
        $self->do_error(400, 
            { error_msg => "No collection matching $col_name"});
        return;
    }

    my $object  = $collection->find_iid($id);

    if ( $object->meta->does_role("Scot::Role::Permittable") ) {
        my $users_groups    = $self->session('groups');
        unless ( $object->is_modifiable($users_groups) ) {
            $self->modify_not_permitted_error;
            return;
        }
        $log->trace("Update is permittable");
    }


    if ( ref($object) eq "Scot::Model::Entry" ) {
        $self->do_task_checks($req_href);
    }

    if ( $object->meta->does_role("Scot::Role::Ownable") ) {
        # only admin can change ownership, unless this is an task entry
        # and then you can only take ownership
        if ( $req_href->{params}->{owner} ) {
            # the request wants to change the owner
            if ( $self->ownership_change_permitted($req_href, $object) ) {
                $log->warn("Ownership change of ".ref($object)." ".$object->id .
                            " from ".$object->owner." to ".
                            $req_href->{params}->{owner});
            }
            else {
                $log->error("Non permitted ownership change! ".
                            ref($object) . " ". $object->id . " to ".
                            $req_href->{params}->{owner});
                $self->do_error(403, {
                    error_msg   => "Insufficient privilege to complete request"
                });
                return
            }
        }
        else {
            $log->trace("No ownership change detected");
        }
    }

    my %update;
    foreach my $key ( keys %{$req_href->{params}} ) {
        my $value       = $req_href->{params}->{$key};
        $update{$key}   = $value;
    }
    $update{updated} = $env->now();

    $log->trace("Updating" . ref($object) . "id = ".$object->id . " with ",
        { filter =>\&Dumper, value => \%update});

    unless ( $object->update({ '$set' => \%update }) ) {
        $log->error("Problem applying update for $col_name");
        $log->error("update was: ", { filter => \&Dumper, value => \%update});
        $self->do_error(444, { error_msg => "Failed Update" });
        return;
    }

    $log->trace("Updated object");

    $env->amq->send_amq_notification("update", $object, $user);

    $self->do_render({
        id      => $object->id,
        status  => "successfully updated",
    });

    $self->audit("update_thing", $req_href);
}

sub do_task_checks {
    my $self        = shift;
    my $req_href    = shift;
    my $user        = $self->session('user');

    my $key;
    my $status;
    my $now = $self->env->now();
    my $params  = $req_href->{params};

    if ( defined $params->{make_task} ) {
        $key = "make_task";
        $params->{is_task}  = 1;
        $status = "open";
    }
    elsif ( defined $params->{take_task} ) {
        $key    = "take_task";
        $status = "assigned";
    }
    elsif ( defined $params->{close_task} ) {
        $key    = "close_task";
        $status = "closed";
    }

    delete $params->{$key};
    $params->{task} = {
        who     => $user,
        when    => $now,
        status  => $status,
    };
}

sub ownership_change_permitted {
    my $self    = shift;
    my $request = shift;
    my $object  = shift;

    if ( $self->user_is_admin ) {
        # admin user can change any ownership
        return 1;
    }

    if ( ref($object) eq "Scot::Model::Entry" ) {
        # task ownership can be assumed by a normal person
        if ( $object->is_task ) {
            if ( $request->{params}->{owner} eq $self->session('user') ) {
                # but only assumed by the requestor not pushed onto someone else
                return 1;
            }
            else {
                return undef;
            }
        }
        else {
            return undef;
        }
    }
}

=item B<DELETE /scot/api/v2/:thing/:id>

=pod

@api {delete} /scot/api/v2/:thing/:id
@apiName Delete thing
@apiGroup CRUD
@apiDescription Delete thing 
@apiParam {String} thing The "alert", "event", "incident", "intel", etc. you wish to retrieve

@apiExample Example Usage
    curl -X DELETE https://scotserver/scot/api/v2/event/123 

@apiSuccessExample {json} Success-Response:
    HTTP/1.1 200 OK
    {
        id : 123,
        thing: "event",
        status : "ok",
        action: "delete"
    }

=cut

sub delete {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $user    = $self->session('user');

    $log->trace("Handler is processing a DELETE ONE request by $user");

    my $req_href    = $self->get_request_params;
    my $id          = $req_href->{id};
    my $col_name    = $req_href->{collection};

    unless ( $self->id_is_valid($id) ) {
        $self->do_error(400, {
            error_msg   => "Invalid integer id: $id"
        });
        return;
    }
    
    my $collection;

    try {
        $collection  = $mongo->collection($col_name);
    }
    catch {
        $self->do_error(400, {
            error_msg   => "Collection problem"
        });
        return;
    };

    unless ( defined $collection ) {
        $self->do_error(400, {
            error_msg => "No collection matching $col_name"
        });
        return;
    }

    my $object  = $collection->find_iid($id);

    unless ( defined $object ) {
        $log->error("No matching Object for $col_name : $id");
        $self->do_error(404, {
            error_msg   => "No matching object $col_name: $id"
        });
        return;
    }

    if ( $object->meta->does_role("Scot::Role::Permittable") ) {
        my $users_groups    = $self->session('groups');
        unless ( $object->is_modifiable($users_groups) ) {
            $self->modify_not_permitted_error;
            return;
        }
    }


    if  ( $req_href->{purge} and $self->user_is_admin ) {
        $log->warn( "Object is being purged.", 
                    { filter=>\&Dumper, value => $object->as_hash});
    } 
    else {
        my $del_collection  = $mongo->collection("Deleted");
        my $href            = $object->as_hash;
        my $del_obj         = $del_collection->create({
            when    => $env->now(),
            who     => $self->session('user'),
            type    => ref($object),
            data    => $href,
        });
    }

    $object->remove;
    
    $env->amq->send_amq_notification("delete", $object, $user);

    $self->do_render({
        action      => 'delete',
        thing       => $col_name,
        id          => $object->id,
        status      => 'ok',
    });
    
    $self->audit("delete_thing", $req_href);

}

sub get_alertgroup_subthing {
    my $self        = shift;
    my $id          = shift;
    my $thing       = shift;
    my $subthing    = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;

    $log->trace("Getting Alertgroup $subthing data");

    if ( $subthing eq "alert" ) {
        my $collection  = $mongo->collection('Alert');
        my $cursor      = $collection->get_alerts_in_alertgroup($id);
        return $cursor;
    }

    if ( $subthing eq "guide" ) {
        my $collection  = $mongo->collection('Guide');
        my $cursor      = $collection->get_guide(
            target_id   => $id + 0,
            target_type => $thing,
        );
        return $cursor;
    }

    if ( $subthing eq "history" ) {
        return $self->get_history($id, $thing);
    }

    if ( $subthing eq "entity" ) {
        return $self->get_entities($id, $thing);
    }

    if ( $subthing eq "entry" ) {
        return $self->get_entries($id, $thing);
    }

    $log->error("Unsupported subthing $subthing for $thing");
}

sub get_alert_subthing {
    my $self        = shift;
    my $id          = shift;
    my $thing       = shift;
    my $subthing    = shift;
    my $env         = $self->env;
    my $mongo       = $self->mongo;
    my $log         = $self->log;

    $log->trace("Getting $thing $subthing data");

    if ( $subthing eq "entity" ) {
        return $self->get_entities($id, $thing);
    }

    if ( $subthing eq "entry" ) {
        return $self->get_entries($id, $thing);
    }

    $log->error("Unsupported subthing $subthing for $thing");
}

sub get_tags {
    my $self    = shift;
    my $id      = shift;
    my $thing   = shift;

    my $mongo       = $self->env->mongo;
    my $collection  = $mongo->collection('Tag');
    my $cursor      = $collection->get_tags(
        target_id   => $id + 0,
        target_type => $thing,
    );
    return $cursor;
}

sub get_sources {
    my $self    = shift;
    my $id      = shift;
    my $thing   = shift;

    my $mongo       = $self->env->mongo;
    my $collection  = $mongo->collection('Source');
    my $cursor      = $collection->get_sources(
        target_id   => $id + 0,
        target_type => $thing,
    );
    return $cursor;
}


sub get_entries {
    my $self    = shift;
    my $id      = shift;
    my $thing   = shift;

    my $mongo   = $self->env->mongo;
    my $collection  = $mongo->collection('Entry');
    my $cursor      = $collection->get_entries(
        target_id   => $id + 0,
        target_type => $thing,
    );
    return $cursor;
}

sub get_entities {
    my $self    = shift;
    my $id      = shift;
    my $thing   = shift;
    my $mongo   = $self->env->mongo;
    my $collection  = $mongo->collection('Entity');
    my $cursor      = $collection->get_entities(
        target_id   => $id + 0,
        target_type => $thing,
    );
    return $cursor;
}

sub get_history {
    my $self    = shift;
    my $id      = shift;
    my $thing   = shift;
    my $mongo   = $self->env->mongo;
    my $collection  = $mongo->collection('Audit');
    my $cursor      = $collection->get_history({
        target_id   => $id + 0,
        target_type => $thing,
    });
    return $cursor;
}

sub get_event_subthing {
    my $self        = shift;
    my $id          = shift;
    my $thing       = shift;
    my $subthing    = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;

    $log->trace("Getting Event $subthing data");

    if ( $subthing eq "history" ) {
        return $self->get_history($id, $thing);
    }

    if ( $subthing eq "entity" ) {
        return $self->get_entities($id, $thing);
    }

    if ( $subthing eq "entry" ) {
        return $self->get_entries($id, $thing);
    }

    if ( $subthing eq "tag" ) {
        return $self->get_tags($id, $thing);
    }

    if ( $subthing eq "source" ) {
        return $self->get_sources($id, $thing);
    }

    $log->error("Unsupported subthing $subthing for $thing");
}

sub get_incident_subthing {
    my $self        = shift;
    my $id          = shift;
    my $thing       = shift;
    my $subthing    = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;

    $log->trace("Getting Incident $subthing data");

    if ( $subthing eq "history" ) {
        return $self->get_history($id, $thing);
    }

    if ( $subthing eq "entity" ) {
        return $self->get_entities($id, $thing);
    }

    if ( $subthing eq "entry" ) {
        return $self->get_entries($id, $thing);
    }

    if ( $subthing eq "tag" ) {
        return $self->get_tags($id, $thing);
    }

    if ( $subthing eq "source" ) {
        return $self->get_sources($id, $thing);
    }


    $log->error("Unsupported subthing $subthing for $thing");
}

sub get_intel_subthing {
    my $self        = shift;
    my $id          = shift;
    my $thing       = shift;
    my $subthing    = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;

    $log->trace("Getting $thing $subthing data");

    if ( $subthing eq "history" ) {
        return $self->get_history($id, $thing);
    }

    if ( $subthing eq "entity" ) {
        return $self->get_entities($id, $thing);
    }

    if ( $subthing eq "entry" ) {
        return $self->get_entries($id, $thing);
    }

    $log->error("Unsupported subthing $subthing for $thing");
}

=item B<user_is_admin>

returns true if one of the user's groups is "admin"

=cut

sub user_is_admin {
    my $self    = shift;
    my $groups  = $self->session('groups');
    if ( grep { /admin/ } @{$groups} ) {
        return 1;
    }
    return undef;
}

sub get_object_collection {
    my $self    = shift;
    my $object  = shift;
    my $thing   = lc((split(/::/,ref($object)))[-1]);
    return $thing;
}

sub do_error {
    my $self    = shift;
    my $code    = shift;
    my $href    = shift;
    $self->render(
        status  => $code,
        json    => $href,
    );
}

sub do_render {
    my $self    = shift;
    my $code    = 200;
    my $href    = shift;
    $self->render(
        status  => $code,
        json    => $href,
    );
}

=item B<id_is_valid($id)>

returns true if $id looks like an integer.
currently a simplistic check of /^\d+$/

=cut

sub id_is_valid {
    my $self    = shift;
    my $id      = shift;

    if ( $id =~ /^\d+$/ ) {
        return 1;
    }
    return undef;
}

=item B<read_not_permitted_error()>

sends a 403 to client with error message 

=cut

sub read_not_permitted_error {
    my $self    = shift;
    my $obj     = shift;
    my $log     = $self->env->log;
    my $user    = $self->session('user');
    $log->error("User $user attempted to access ". ref($obj) . " ".
                $obj->id . "readgroups [ ".join(',', $obj->all_readgroups) 
                ."]");
    $self->do_error(403, {
        error_msg   => "Read Not Permitted"
    });
}

=item B<modify_not_permitted_error()>

sends a 403 to client with error message 

=cut

sub modify_not_permitted_error {
    my $self    = shift;
    my $obj     = shift;
    my $log     = $self->env->log;
    my $user    = $self->session('user');

    $log->error("User $user attempted to access ". ref($obj) . " ".
                $obj->id . "modifygroups [ ".join(',', $obj->all_modifygroups) 
                ."]");
    $self->do_error(403, {
        error_msg   => "Modify Not Permitted"
    });
}

=item B<nothing_matching_error()>

sends a 404 to client with error message 

=cut

sub nothing_matching_error {
    my $self    = shift;
    my $match   = shift;
    my $log     = $self->env->log;
    $log->error("Nothing matches: ",{ filter => \&Dumper, value=>$match});
    $self->do_error(404, {
        error_msg       => "Nothing Matches",
        match_condition => $match,
    });
}

=item B<build_match_ref($href)>

builds a hash of key value pairs that will be used to query the
mongodb for a document.  $href is a hash ref from request, and we
specifically are looking at the href withing $href->{params}

=cut

sub build_match_ref {
    my $self    = shift;
    my $href    = shift;
    my $params  = $href->{params};
    my $env     = $self->env;
    my $log     = $env->log;
    my %match;

    if ( defined $params->{gridfilter} ) {

        $log->trace("gridfilter detected");
        
        foreach my $href (@{$params->{gridfilter}}) {
            my ($column, $filter ) = each %{$href};
            next unless (defined $column);

            if ( $self->is_epoch_column($column) ) {
                $log->trace("epoch column detected");
                my ($start,$end) = split(/::/, $filter, 2);
                $params->{$column} = {
                    '$gte'  => $start + 0,
                    '$lte'  => $end + 0, 
                };
            }
            elsif ( $self->is_int_column($column) ) {
                $log->trace("int column detected");
                $params->{$column} = $filter +0;
            }
            else{
                $params->{$column} = $filter;
            }
        }
        delete $params->{gridfilter};
    }

    foreach my $key ( keys %$params ) {
        next if $key eq "sorts";
        next if $key eq "fields";
        next if $key eq "offset";
        next if $key eq "limit";
        next if $key eq "all";
        next if $key eq "page";
        next if $key eq "perpage";
        next if $key eq "filter_end";
        if ( $self->is_epoch_column($key) ) {
            $match{$key} = $params->{$key};
        }
        elsif ( $self->is_int_column($key) ) {
            $match{$key} = $params->{$key}+0;
        }
        else {
            $match{$key} = qr/$params->{$key}/;
        }
    }
    $self->env->log->debug("Matching: ", {filter=>\&Dumper, value=>\%match});
    return \%match;
}

=item B<build_sort_opts($href)>

Get sort options from the request
$href->{sorts} = [
    { column => 1},
    { column2 => -1}
]

=cut

sub build_sort_opts {
    my $self    = shift;
    my $href    = shift;
    my $params  = $href->{params};
    my $aref    = $params->{sorts};
    my %sort;

    foreach my $sorthref ( @$aref ) {
        my ( $col, $dir) = each %$sorthref;
        $sort{$col} = $dir + 0;
    }
    if (scalar(keys %sort) > 0) {
        return \%sort;
    }
    
    return undef;
}

=item B<build_limit($href)>

Get the limit value

=cut

sub build_limit {
    my $self    = shift;
    my $href    = shift;
    my $params  = $href->{params};
    my $limit   = $params->{limit}//$params->{perpage};
    return $limit;
}

=item B<build_offset($href)>

get the offset value

=cut

sub build_offset {
    my $self        = shift;
    my $href        = shift;
    my $params      = $href->{params};
    return $params->{offset};
}

=item B<build_fields($href)>

set the fields that you wish to return

=cut

sub build_fields {
    my $self        = shift;
    my $href        = shift;
    my $params      = $href->{params};
    my $aref        = $params->{fields};
    my %fields;

    foreach my $f (@$aref) {
        $fields{$f} = 1;
    }

    if ( scalar(keys %fields) > 0 ) {
        return \%fields;
    }
    return undef;
}

=item B<disambiguate($value)>

take the value and see if looks like JSON, if it does, return the 
parsed result, otherwise return $value.

=cut

sub disambiguate {
    my $self    = shift;
    my $value   = shift;
    my $log     = $self->env->log;

    # try to convert it from JSON, if it fails, then it must be a simple 
    # value.  

    my $return;
    eval {
        $return = decode_json($value);
    };
    if ($@) {
        # $log->trace("Appears not to be JSON. ($@)");
        # $log->debug("value = ".Dumper($value));
        $return = $value;
    }
    return $return;
}

=item B<get_request_params>

Examine the request from the webserver and stuff the params and json
into an HREF

=cut 

sub get_request_params  {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $req     = $self->req->params->to_hash;
    my $json    = $self->req->json;

    my $input_href;

    if ( defined $req ) {
        foreach my $key ( keys %$req ) {
            my $value   = $req->{$key};
            my $lckey   = lc($key);
            if ( $key eq "id" or $key eq "offset" or $key eq "limit") {
                $input_href->{$lckey}    = $value + 0;
                next;
            }
            if ( $key =~ /sorts\[/ ) {
                # need to put check in for +- before field name
                (my $column = $key) =~ s/sorts\[(.*)\]/$1/;
                push @{$input_href->{sorts}}, { $column => $value };
                next;
            }
            if ( $key eq "fields" ) {
                $input_href->{$lckey} = $value;
                next;
            }
            $input_href->{$lckey} = $self->disambiguate($value);
        }
    }

    # implicit trumping of json input over parameter data
    if ( defined $json ) {
        foreach my $key ( keys %$json ) {
            my $lckey   = lc($key);
            $input_href->{$lckey} = $json->{$key};
        }
    }

    my $data = {
        collection  => $self->stash('thing'),
        id          => $self->stash('id'),
        subthing    => $self->stash('subthing'),
        params      => $input_href,
    };
    $log->debug("Input: ", { filter => \&Dumper, value => $data });
    return $data;
}

sub thread_entries {
    my $self    = shift;
    my $cursor  = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my @threaded    = ();
    my %where       = ();
    my $rindex      = 0;
    my $count       = 1;
    my $mygroups    = $self->session('groups');
    my $user        = $self->session('user');

    ENTRY:
    while ( my $entry   = $cursor->next ) {

        unless ( $entry->is_readable($mygroups) ) {
            $log->debug("Entry ".$entry->id." is not readable by $user");
            next ENTRY;
        }

        $count++;
        my $href            = $entry->as_hash;
        $href->{children}   = [];
        

        if ( $entry->parent == 0 ) {
            $threaded[$rindex]  = $href;
            $where{$entry->id}  = \$threaded[$rindex];
            $rindex++;
            next ENTRY;
        }

        my $parent_ref          = $where{$entry->parent};
        my $parent_kids_aref    = $$parent_ref->{children};
        my $child_count         = 0;

        if ( defined $parent_kids_aref ) {
            $child_count    = scalar(@{$parent_kids_aref});
        }

        my $new_child_index = $child_count;
        $parent_kids_aref->[$new_child_index]  = $href;
        $where{$entry->id} = \$parent_kids_aref->[$new_child_index];
    }

    return wantarray ? @threaded : \@threaded;
}

sub autocomplete {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $thing   = $self->stash('thing');
    my $query   = $self->param('q');

    $log->trace("Autocomplete request for $thing ($query)");

    my %class   = (
        tag     => 'Tag',
    );

    my $collection  = $mongo->collection($class{$thing});
    my $results     = $collection->get_autocomplete($query);

    $self->do_render(200, $results);
}

=head2 Special Routes

=cut

sub promote {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;

    my $req_href    = $self->get_request_params;
    my $id          = $req_href->{params}->{id};  # array ref
    my $col_name    = $req_href->{collection};

    my $collection  = $mongo->collection(ucfirst($col_name));
    my $cursor      = $collection->find({id => {'$in' => $id}});

    if ( $col_name eq "alertgroup" ) {
        # should be rare, waiting to implement    
    }

    if ( $col_name eq "alert" ) {
        # promote an alert to an event
        $self->promote_alert($cursor);
    }

    if ( $col_name eq "event" ) {
        # promote an event to an incident
        $self->promote_event($cursor);
    }
}

sub get_alertgroup_subject {
    my $self    = shift;
    my $alert   = shift;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Alertgroup');
    my $obj     = $col->find_iid($alert->alertgroup);
    if ( $obj ) {
        return $obj->subject;
    }
    $self->env->log->error("Did not fine Alertgroup ".$alert->alertgroup);
    return "please create a subject";
}

sub promote_alert {
    my $self    = shift;
    my $cursor  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $alert   = $cursor->next;
    my $subject = $self->get_alertgroup_subject($alert);

    my $href    = {
        subject     => $subject,
        alerts      => [ $alert->id ],
        owner       => $self->session('user'),
        when        => $env->now(),
        readgroups  => $env->default_groups->{readgroups},
        modifygroups=> $env->default_groups->{modifygroups},
    };
    my $procol  = $mongo->collection('Event');
    my $event   = $procol->create($href);

    unless ($event) {
        $log->error("Failed to create EVENT during promotion!");
        $self->do_error(400, {
            error_msg => "Failed to create Event during alert promotion!"
        });
        return undef;
    }

    # reversing normal while loop semantics here because this will allow 
    # the case where the Cursor has only one alert in it.
    do {
        my $entryhref   = {
            target_id       => $event->id,
            target_type     => "event",
            updated         => $env->now(),
            when            => $env->now(),
            readgroups      => $event->readgroups,
            modifygroups    => $event->modifygroups,
            body            => $self->html_alert_data($alert),
        };
        my $entrycol    = $mongo->collection('Entry');
        my $entry       = $entrycol->create($entryhref);

        unless ($entry) {
            $log->error("Failed to create Event ".$event->id." first entry");
            $self->do_error(400, {
                error_msg => "Entry creation failed for promotion of alert ".
                $alert->id. " to event ". $event->id });
            return undef;
        }
        $event->update_add(alerts => $alert->id);
    } while ( $alert = $cursor->next );

    $self->do_render({
        action  => 'promote alert',
        status  => 'ok',
        id      => $event->id,
        thing   => "event",
    });     

    $self->audit("promote_alert", {
        thing   => "event",
        id      => $event->id,
    });
}

sub promote_event {
    my $self    = shift;
    my $cursor  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my @events  = $cursor->all;
    my @eids    = map { $_->id } @events;
    my $event   = $events[0];
    my $subject = $event->subject;

    my $rg  = defined ($event->readgroups) 
        ? $event->readgroups 
        : $env->defaultgroups->{readgroups};
    my $mg  = defined ($event->modifygroups) 
        ? $event->modifygroups 
        : $env->defaultgroups->{modifygroups};

    my $incidenthref    = {
        owner       => $self->session('user'),
        readgroups  => $rg,
        modifygroups=> $mg,
        events      => \@eids,
        subject     => $event->subject,
    };

    my $inc_collection  = $mongo->collection('Incident');
    my $incident        = $inc_collection->create($incidenthref);

    unless ($incident) {
        $log->error("Failed to create Incident during promotion!");
        $self->do_error(400, {
            error_msg => "Failed to create Incident during Event promotion!"
        });
        return undef;
    }

    $self->do_render({
        action      => 'promote event',
        status      => 'ok',
        id          => $incident->id,
        thing       => 'incident',
    });
    $self->audit("promote_event", {
        thing   => "incident",
        id      => $incident->id,
    });
}

sub html_alert_data {
    my $self    = shift;
    my $alert   = shift;
    my $data    =  $alert->data_with_flair;
    my $columns = $alert->columns;
    my $html    = qq|<table class="alert_data_table"><tr>|;
    foreach my $col (@$columns) {
        $html .= qq| <th>$col</th> |;
    }
    $html .= "</tr><tr>";
    foreach my $col (@$columns) {
        $html .= qq| <td>$data->{$col}</td> |;
    }
    $html .= "</tr></table>";
    return $html;
}

=item B<audit($what, $data)>

this function creates an audity entry

=cut

sub audit {
    my $self        = shift;
    my $what        = shift;
    my $data        = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $col         = $mongo->collection('Audit');
    my $audit       = $col->create({
        who     => $self->session('user') // 'unknown',
        when    => $env->now(),
        what    => $what,
        data    => $data,
    });
}

sub mypack {
    my $self    = shift;
    my $thing   = shift;
    
    if ( ref($thing) =~ /Scot::Model/ ) {
        my $href    = $thing->pack;
        return $href;
    }
    if ( ref($thing) eq "HASH" ) {
        return $thing;
    }
}
    


1;
