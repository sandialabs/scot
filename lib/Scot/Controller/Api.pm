package Scot::Controller::Api;


=head1 Name

Scot::Controller::Api

=head1 Description

Perform the CRUD operations based on JSON input and provide JSON output

=cut

use Data::Dumper;
use Try::Tiny;
use Mojo::JSON qw(decode_json encode_json);
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

    my $req_href    = $self->get_request_params;
    #   req_href = {
    # collection  => "collection name",
    # id          => $int_id,
    # subthing    => $if_it_exists,
    # user        => $username,
    # request     => {
    #     params  => $href_of_params_from_web_request,
    #     json    => $href_of_json_submitted
    # }
    

    my $thing   = $req_href->{collection};
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

    my $object  = $collection->create_from_api($req_href);

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
    #   req_href = {
    # collection  => "collection name",
    # id          => $int_id,
    # subthing    => $if_it_exists,
    # user        => $username,
    # request     => {
    #     params  => $href_of_params_from_web_request,
    #     json    => $href_of_json_submitted
    # }
    # where params or json is
    #  {
    #    match : { mongo json match query },
    #    sort  : { mongo sorting },
    #    columns: [ col1, ... ], # display only these columns
    #    limit: x,
    #    offset: y
    #  }

    $log->debug("Request = ", {filter=>\&Dumper, value=>$req_href});

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

    if ( $col_name eq "handler"  and defined $req_href->{request}->{params}->{current}) {
        my $handler_obj = $collection->get_handler($req_href->{request}->{params}->{current});
        if ( $handler_obj ) {
            my $hash    = $handler_obj->as_hash;
            $self->do_render({
                records             => $hash,
                queryRecordCount    => 1,
                totalRecordCount    => 1,
            });
        }
        else {
            $self->do_render({
                records         => {
                    username    => 'unassigned',
                },
                queryRecordCount    => 1,
                totalRecordCount    => 1,
            });
        }
        $self->audit("get_current_handler", $req_href);
        return;
    }

    $match_ref   = $req_href->{request}->{params}->{match} // 
                   $req_href->{request}->{json}->{match};
                   
    unless ( $match_ref ) {
        $log->debug("Empty match_ref! Easy, peasey");
        $match_ref  = {};
    }
    else {
        $log->debug("Looking for $col_name matching ",{filter=>\&Dumper, value=>$match_ref});
    }

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

    delete $req_href->{request}; # hack to kil error when '$' appears in match ref

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

    $log->debug("Request = ", { filter =>\&Dumper, value => $req_href});

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

    if ( $object->meta->does_role("Scot::Role::Permission") ) {
        my $users_groups    = $self->session('groups');
        unless ( $object->is_modifiable($users_groups) ) {
            $self->modify_not_permitted_error($object, $users_groups);
            return;
        }
        $log->trace("Update is permittable");
        # only admin can change ownership, unless this is an task entry
        # and then you can only take ownership
        my $newowner    = $req_href->{request}->{params}->{owner} // 
                          $req_href->{request}->{json}->{owner};

        if ( $newowner ) {
            # the request wants to change the owner
            if ( $self->ownership_change_permitted($req_href, $object) ) {
                $log->warn("Ownership change of ".ref($object)." ".$object->id .
                            " from ".$object->owner." to ".  $newowner);
            }
            else {
                $log->error("Non permitted ownership change! ".
                            ref($object) . " ". $object->id . " to ".  $newowner);
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


    if ( ref($object) eq "Scot::Model::Entry" ) {
        $self->do_task_checks($req_href);
    }

    if ( $object->meta->does_role("Scot::Role::Promotable") ) {
        # check for a promotion
        # promote => 'new'  === create new next object up heirarchy
        # promote => int    === add thing to existing object


        my $promote_id  = $self->get_promotion_id($req_href);

        if ( defined $promote_id ) {
            $log->trace("Promotion Detected");
            # create the promotion object
            if (my $pid = $self->promote_thing($req_href, $promote_id, $col_name, $object)) {
                $log->debug("Promoted $col_name");
                $self->do_render({
                    id      => $object->id,
                    status  => "successfully promoted",
                    pid     => $pid,
                });
                return;
            }
            else {
                $log->error("Failed Promotion!");
                $self->do_error(444, { error_msg => "Promotion Failed" });
                return;
            }
        }

        my $unpromote = $self->get_unpromote($req_href);

        if ( $unpromote ) {

            if ( $self->unpromote_thing($req_href, $object, $unpromote) ) {
                $self->do_render({
                    id      => $object->id,
                    status  => "successfully unpromoted",
                });
                return;
            }
            else {
                $log->error("Failed Unpromotion");
                $self->do_error(444, { error_msg => "Unpromotion failure" } );
                return;
            }
        }
    }

    my %update = $self->build_update_doc($req_href);

    $log->trace("Updating " . ref($object) . " id = ".$object->id . " with ",
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

sub build_update_doc {
    my $self    = shift;
    my $request = shift;
    my $params  = $request->{request}->{params};
    my $json    = $request->{request}->{json};
    my %update  = ();
    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Building Update command");

    if ( defined $params ) {

        $log->trace("Params are present...");

        foreach my $key ( keys %{$params} ) {
            my $value       = $params->{$key};
            $update{$key}   = $value;
        }
    }
    if (defined $json) {

        $log->trace("JSON is present...");

        foreach my $key ( keys %{$json} ) {
            $update{$key}   = $json->{$key};
        }
    }
    $update{updated} = $env->now();
    $log->debug("Update command is: ",{filter=>\&Dumper, value=>\%update});
    return wantarray ? %update : \%update;
}

sub get_promotion_id {
    my $self    = shift;
    my $req     = shift;
    
    if ( $req->{request}->{params}->{promote} ) {
        return $req->{request}->{params}->{promote};
    }
    if ( $req->{request}->{json}->{promote} ) {
        return $req->{request}->{json}->{promote};
    }
    return undef;
}

sub get_unpromote {
    my $self    = shift;
    my $req     = shift;

    if ( $req->{request}->{params}->{unpromote} ) {
        return $req->{params}->{unpromote};
    }
    if ( $req->{request}->{json}->{unpromote} ) {
        return $req->{request}->{json}->{unpromote};
    }
    return undef;
}


sub promote_thing {
    my $self    = shift;
    my $req     = shift;
    my $pid     = shift;
    my $colname = shift;
    my $object  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $href;
    my $data    = $req->{request};
    my $user    = $self->session('user');

    $log->trace("Attempting promotion...");

    my $promotion_collection = $self->get_promotion_collection($colname);

    unless ( $promotion_collection ) {
        $log->error("$colname is not promotable or already at max promotion");
        return undef;
    }

    my $pobj;
    my $pcol    = $mongo->collection(ucfirst($promotion_collection)); 
    my $newhref = {};
    my $subject = $data->{params}->{subject} // $data->{json}->{subject};

    if ( $pid =~ /\d+/ ) {

        $log->trace("Promoting to existing $promotion_collection");

        my $pobj    = $pcol->find_iid($pid);
        unless ($pobj) {
            $log->error("Can not promote to non existant id: $pid for $promotion_collection");
            return undef;
        }
        $pobj->update({
            '$set'  => {
                updated     => $env->now,
            },
            '$addToSet' => { 
                'promotions.from'  => { type => $colname, id => $object->id }
            },
        });
        unless ($object->update({
                '$set'  => {
                    updated     => $env->now,
                    status      => 'promoted',
                },
                '$addToSet' => {
                    'promotions.to' => { type => $promotion_collection, id => $pobj->id }
                },
            }) ) {
            $log->warn("failed to update $colname object with promotion status");
        }
        else {
            $env->amq->send_amq_notification("update", $object, $user);
            if ( $promotion_collection eq "event" ) {
                $mongo->collection('Alertgroup')->refresh_data($object->alertgroup);
                my $agobj = $mongo->collection('Alertgroup')->find_iid($object->alertgroup);
                $env->amq->send_amq_notification("update", $agobj, $user);
            }
        }
        return $pobj->id;
    }

    # OK, getting hear means we are creating a new promotion object

    if ( $promotion_collection eq "event" ) {
        # this kind of promotion can have a subject and an initial entry specified

        $log->trace("Promoting to a new event");

        my $agobj = $mongo->collection('Alertgroup')->find_iid($object->alertgroup);

        unless ($subject) {
            $subject    = $agobj->subject;
        }

        my $pobj    = $pcol->create({
            subject => $subject,
            status  => "open",
            promotions  => {
                from    => [ { type => "alert", id => $object->id } ],
            },
        });

        unless ( $pobj ) {
            $log->error("Failed to create $promotion_collection object!");
            return undef;
        }
        $env->amq->send_amq_notification("create", $pobj, $user);
        
        my $entrybody = $data->{params}->{entrybody} // 
                        $data->{json}->{entrybody};
        my $summary   = $data->{params}->{summary} //
                        $data->{json}->{summary};

        if ( $entrybody) {
            # need to create an entry;
            my $entry   = $mongo->collection("Entry")->create({
                body        => $entrybody,
                target_id   => $pobj->id,
                target_type => $promotion_collection,
                summary     => $summary ? 1 : 0,
            });

            unless ($entry) {
                $log->warn("failed to create the entry with body $entrybody");
            }
            else {
                $env->amq->send_amq_notification("create", $entry, $user);
            }
        }

        unless ($object->update({
            '$set'  => {
                updated     => $env->now,
                status      => 'promoted',
            },
            '$addToSet' => {
                'promotions.to' => { type => $promotion_collection, id => $pobj->id }
            },
        }) ) {
            $log->warn("Failed to update $colname object with promotion status");
        }
        else {
            $mongo->collection('Alertgroup')->refresh_data($object->alertgroup);
            $env->amq->send_amq_notification("update", $object, $user);
            $env->amq->send_amq_notification("update", $agobj, $user);
        }
        return $pobj->id;
    }

    # must be an event to incident transition

    $log->trace("Promoting to an incident");

    unless ($subject) {
        $subject    = $object->subject;
    }

    my $reportable  = $data->{params}->{reportable} //
                      $data->{json}->{reportable};
    my $chref   = {
        reportable  => $reportable ? 1 : 0,
        subject     => $subject,
        promotions  => {
            from    => [ { type => "event", id => $object->id } ],
            to      => [],
        },
    };
    my $category    = $data->{params}->{category} //
                      $data->{json}->{category};
    $chref->{category} = $category if (defined $category);

    my $sensitivity   = $data->{params}->{sensitivity} //
                      $data->{json}->{sensitivity};
    $chref->{sensitivity} = $sensitivity if (defined $sensitivity);

    my $occurred    = $data->{params}->{occurred} //
                      $data->{json}->{occurred};
    $chref->{occurred} = $occurred if (defined $occurred);

    my $discovered  = $data->{params}->{discovered} //
                      $data->{json}->{discovered};
    $chref->{discovered} = $occurred if (defined $discovered);

    my $incident    = $mongo->collection('Incident')->create($chref);

    unless ( $incident ) {
        $log->error("Failed to create $promotion_collection object!");
        return undef;
    }
    $env->amq->send_amq_notification("create", $incident, $user);

    unless ( $object->update({
        '$set'  => {
            updated => $env->now(),
            status  => "promoted",
        },
        '$addToSet' => {
            'promotions.to'   => { type => $promotion_collection, id => $incident->id }
        },
    }) ) {
        $log->warn("Failed to update $colname object with promotion status!");
    }
    $env->amq->send_amq_notification("update", $object, $user);
    return $incident->id;
}

sub get_promotion_collection {
    my $self    = shift;
    my $name    = shift;
    
    if ($name eq "alert") {
        return "event";
    }
    if ($name eq "event") {
        return "incident";
    }
    return undef;
}

sub do_task_checks {
    my $self        = shift;
    my $req_href    = shift;
    my $user        = $self->session('user');
    my $env         = $self->env;
    my $log         = $env->log;

    my $key;
    my $status;
    my $now = $env->now();
    my $params  = $req_href->{request}->{json} // $req_href->{request}->{params} ;

    $log->debug("Checking For Task Changes: ", { filter =>\&Dumper, value=>$params });

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

    #
    # delete actually just moves the data to the deleted collection
    # UNLESS, $req_href->{request}->{params}->{purge} is true
    # and then it is truly deleted from the collection (no undo)
    # if the user is an admin
    #

    my $req_href    = $self->get_request_params;
    my $id          = $req_href->{id};
    my $col_name    = $req_href->{collection};

    my $purge       = $req_href->{request}->{param}->{purge} // 
                      $req_href->{request}->{json}->{purge};

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
            $self->modify_not_permitted_error($object, $users_groups);
            return;
        }
    }


    if  ( $purge and $self->user_is_admin ) {
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
    my $users_groups    = shift;
    my $log     = $self->env->log;
    my $user    = $self->session('user');

    $log->error("User $user [". join(',', @{$users_groups}). 
                "] attempted to access ". ref($obj) . " ".
                $obj->id . " modifygroups [ ".join(',', @{$obj->groups->{modify}}) 
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
    my $request = $href->{request};
    my $params  = $request->{params};
    my $json    = $request->{json};

    my $sorthref    = $params->{sort} // $json->{sort};
    return $sorthref;

}

=item B<build_limit($href)>

Get the limit value

=cut

sub build_limit {
    my $self    = shift;
    my $href    = shift;
    my $request = $href->{request};
    my $params  = $request->{params};
    my $json    = $request->{json};

    my $limit   = $params->{limit} // $json->{limit};
    return $limit;
}

=item B<build_offset($href)>

get the offset value

=cut

sub build_offset {
    my $self        = shift;
    my $href        = shift;
    my $request     = $href->{request};
    my $params      = $request->{params};
    my $json        = $request->{json};
    return $params->{offset} // $json->{offset};
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
into an HREF = {
    collection  => "collection name",
    id          => $int_id,
    subthing    => $if_it_exists,
    user        => $username,
    request     => {
        params  => $href_of_params_from_web_request,
        json    => $href_of_json_submitted
    }

json for a get many looks like
{
    match: {
        '$or' : [
            {
                col1: { '$in': [ val1, val2, ... ] },
                col2: "foobar"
            },
            {
                col3: "boombaz"
            }
        ]
    },
    sort: { 
        updated => -1,
    }
    limit: 10,
    offset: 200
}


=cut 

sub get_request_params  {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $params  = $self->req->params->to_hash;
    my $json    = $self->req->json;

    $log->trace("params => ", { filter => \&Dumper, value => $params });
    $log->trace("json   => ", { filter => \&Dumper, value => $json });

    if ( $params ) {
        $log->trace("Checking Params for JSON values");
        foreach my $key (keys %{$params}) {
            $log->trace("param ". Dumper($key) ." = ", {filter=>\&Dumper, value => $params->{$key}});
            my $parsedjson;
            eval {
                $parsedjson = decode_json($params->{$key});
            };
            if ($@) {
                $log->debug("no json detected, keeping data...");
                $parsedjson = $params->{$key}; # not really json!
            }
            $params->{$key} = $parsedjson;
        }
    }

    my %request = (
        collection  => $self->stash('thing'),
        id          => $self->stash('id'),
        subthing    => $self->stash('subthing'),
        user        => $self->session('user'),
        request     => {
            params  => $params,
            json    => $json,
        },
    );

    return wantarray ? %request : \%request;
}

sub thread_entries {
    my $self    = shift;
    my $cursor  = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("Threading ". $cursor->count . " entries...");

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

sub is_epoch_column {
    my $self    = shift;
    my $col     = shift;
    my $env     = $self->env;
    my $log     = $self->env->log;

    my $count   = grep { /$col/ } $env->get_epoch_cols;

    if ( $count and $count > 0 ) {
        return 1;
    }
    return undef;
}

sub is_int_column {
    my $self    = shift;
    my $col     = shift;
    my $env     = $self->env;
    
    my $count   = grep { /$col/ } $env->get_int_cols;

    if ( $count and $count > 0 ) {
        return 1;
    }
    return undef;
}

sub unpromote_thing {
    my $self    = shift;
    my $req     = shift;
    my $object  = shift;
    my $pid     = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $colname = lcfirst((split(/::/, ref($object)))[-1]);

    $log->trace("Unpromoting $colname ".$object->id);

    # object is the thing that was promoted, but now needs to be unpromoted

    if ($colname eq "alert") {
        
        my $mongocmd    = {};
        # remove the "to" 

        my $calcstatus  = $object->status;
        if ( $object->promoted_count == 1 ) {
            $calcstatus = "open";
        }
        my $to  = $object->promotions->{to};

        if ( $pid =~ /^\d+$/ ) {
            $mongocmd   = {
                '$pull' => {
                    'promotions.to'  => { 
                        type => "event", 
                        id => $pid 
                    }
                },
                '$set'  => { 
                    updated    => $env->now,
                    status     => $calcstatus,
                },
                '$inc'  => {
                    promoted_count => -1,
                    open_count     => 1,
                }
            };
        } 
        else {
            $mongocmd   = { 
                '$set'  => { 
                    'promotions.to' => [],
                    updated         => $env->now(),
                    promoted_count  => 0,
                },
                '$inc'  => {
                    open_count  => $object->promoted_count,
                },
            };
        }
        if ($object->update($mongocmd)) {
            $log->debug("update promotions.to field");
        }
        else {
            $log->error("Failed to update promotions.to!");
        }

        # remove the "from" from the referenced object
        my $type        = "event";
        my $pcolname    = ucfirst($type);
        my $pcol    = $mongo->collection($pcolname);
        my $cmd     = {
            '$pull' => { 'promotions.from' => { type => $colname, id => $object->id }}
        };

        if ( $pid =~ /^\d+$/ ) {
            my $pobj    = $pcol->find_iid($pid);
            if ( $pobj->update($cmd) ) {
                $log->debug("Removed promotion from promtions.from");
            }
            else {
                $log->warn("Unable to update promoted object and remove promotions.from");
            }
        }
        else {
            # unpromote all!
            foreach my $id (@$to) {
                my $pobj    = $pcol->find_iid($id);
                if ( $pobj->update($cmd) ) {
                    $log->debug("Removed promotion from promtions.from");
                }
                else {
                    $log->warn("Unable to update promoted object and remove promotions.from");
                }
            }
        }
    }

    if ($colname eq "event") {
        my $mongocmd    = {
            '$pull' => { 'promotions.to' => {
                type    => "incident", id => $pid }
            },
            '$set'  => { 
                updated => $env->now,
                status  => "open",
            }
        };
        my $to          = $object->promotions->{from};

        my $type        = "incident";
        my $pcolname    = ucfirst($type);
        my $pcol        = $mongo->collection($pcolname);
        my $pobj       = $pcol->find_iid($pid);

        if ($object->update($mongocmd)) {
            $log->debug("Unpromoted $colname");
        }
        else {
            $log->warn("Failed to unpromote $colname");
        }

        my $cmd = {
            '$pull' => { 
                'promotions.from'  => {
                    type    => $colname, 
                    id => $object->id 
                }
            },
            '$set'  => {
                updated => $env->now,
                status  => 'open',
            },
        };

        if ($pobj->update($cmd)) {
            $log->debug("Unpromotee $pcolname");
        }
        else {
            $log->warn("Failed to unpromote $pcolname");
        }
    }
}

1;
