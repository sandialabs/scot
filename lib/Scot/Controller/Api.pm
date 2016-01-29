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

    $log->trace("------------");
    $log->trace("Handler is processing a POST (create) from $user");
    $log->trace("------------");

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

    if ( $object->meta->does_role("Scot::Role::Tags") ) {
        $self->apply_tags($req_href, $colname, $object->id);
    }

    $env->amq->send_amq_notification("creation", $object, $user);

    $self->do_render({
        action  => 'post',
        thing   => $colname,
        id      => $object->id,
        status  => 'ok',
    });

    if ( $object->meta->does_role("Historable") ) {
        $mongo->collection('History')->add_history_entry({
            who     => $user,
            what    => "created via api",
            when    => $env->now,
            targets => { id => $object->id, type => $thing },
        });
    }

    $self->audit("create_thing", {
        thing   => $self->get_object_collection($object),
        id      => $object->id,
    });
}

sub apply_tags {
    my $self        = shift;
    my $req         = shift;
    my $col         = shift;
    my $id          = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $tag_aref    = $self->get_value_from_request($req, "tag");
    if ( $tag_aref ) {
        foreach my $tag (@$tag_aref) {
            $mongo->collection('Tag')->add_tag_to($col, $id, $tag);
        }
    }
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
    #    match : { 
    #           col_name_1: condition,
    #           col_name_2: condition,
    #    },
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
  
     $match_ref  = $self->build_match_ref($match_ref);    

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

    if ( $object->meta->does_role("Scot::Role::Permittable") ) {
        my $users_groups    = $self->session('groups');
        unless ( $object->is_readable($users_groups) ) {
            $self->read_not_permitted_error;
            return;
        }
    }

    if ( $object->meta->does_role("Scot::Role::Views") ) {
        $log->trace("_____ Adding to VIEWS _____");
        my $from = $self->tx->remote_address;
        $object->add_view($user, $from, $env->now);
    }

    my $data_href   = {};
    if ( $req_href->{fields} and 
         $object->meta->does_role("Scot::Role::Hashable")) {
        $data_href  = $object->as_hash($req_href->{fields});
    }
    else {
        $data_href  = $object->as_hash;
    }

    $self->do_render($data_href);

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


    my $req_href    = $self->get_request_params;
    my $id          = $req_href->{id};
    my $thing       = $req_href->{collection};
    my $subthing    = $req_href->{subthing};
    my $collection  = $mongo->collection(ucfirst($thing));
    my $cursor      = $collection->get_subthing($thing, $id, $subthing);

    $log->debug("-----");
    $log->debug("----- GET /$thing/$id/$subthing");
    $log->debug("-----");

    unless ( defined $cursor ) {
        $log->error("No subthing data");
        $self->do_error(404, {
            error_msg   => "No $subthing(s) for object $thing: $id"
        });
        return;
    }

    $log->debug("Subthing cursor has ".$cursor->count." items");

    my @things;
    if ( $subthing eq "entry" ) {
        @things = $self->thread_entries($cursor);
    }
    else {
        # @things = map { $self->mypack($_) } $cursor->all;
        @things = $cursor->all;
    }

    $log->trace("Records are ",{ filter => \&Dumper, value =>\@things});

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

    $log->trace("------------");
    $log->trace("API is processing a PUT update request from $user");
    $log->trace("------------");

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

    my $object;
    try {
        $object = $collection->find_iid($id);
    }
    catch {
        $log->error("Error finding $col_name $id");
        return undef;
    };

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

    if ( $object->meta->does_role("Scot::Role::Entitiable") ) {
        $log->debug("object is Entitiable, checking for discovered entities");
        my $json    = $req_href->{request}->{json};
        my $earef   = $json->{entities};
        delete $json->{entities};

        if ( defined $earef ) {
            if ( scalar(@$earef) > 0 ) {
                $log->debug("we have some!");
                my $ecol    = $mongo->collection('Entity');
                # $ecol->update_entities_from_target($object, $json->{entities});
                $ecol->update_entities($object, $json->{entities});
            }
        }
    }

    if ( $object->meta->does_role("Scot::Role::Tags") ) {
        $self->apply_tags($req_href, $col_name, $id);
    }

    if ( $object->meta->does_role("Scot::Role::Promotable") ) {
        # check for a promotion
        # promote => 'new'  === create new next object up heirarchy
        # promote => int    === add thing to existing object

        my $ret =  $self->handle_promotion($object, $req_href);
        if ( $ret >= 0 ) {
            return;
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

    if ( $object->meta->does_role("Historable") ) {
        $mongo->collection('History')->add_history_entry({
            who     => $user,
            what    => "updated via api",
            when    => $env->now,
            targets => [ { id => $object->id, type => $col_name } ],
        });
    }

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

sub get_promotion_collection {
    my $self    = shift;
    my $type    = shift;
    my $mongo   = $self->env->mongo;

    if ( $type  eq "alert" ) {
        return "event", $mongo->collection('Event');
    }
    if ( $type eq "event" ) {
        return "incident", $mongo->collection('Incident');
    }
    $self->env->log->error("INVALID PROMOTION TYPE!");
    return undef, undef;
}

sub handle_promotion {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    $log->trace(ref($object)." is promotable, checking if promotion is needed");

    my $promote_to      = $self->get_value_from_request($req, "promote");
    my $unpromote_from  = $self->get_value_from_request($req, "unpromote");

    if ( defined $promote_to and defined $unpromote_from ) {
        $log->error("ERROR: can not promote and unpromote as same time");
        $self->do_error(444, { error_msg => "Promotion and unpromotion conflict" });
        return 0;
    }

    unless ( defined $promote_to or defined $unpromote_from ) {
        $log->trace("No promoting or unpromoting in update.");
        return -1;
    }

    my $object_type         = $object->get_collection_name;
    my $linkcol             = $mongo->collection('Link');
    my ($proname, $procol)  = $self->get_promotion_collection($object_type);
    my $user                = $self->session('user');

    if ( $promote_to ) {
    
        my $proobj;

        if ( $promote_to =~ /\d+/ ) {

            $log->trace("Promoting to an supposedly existing id");
            $proobj  = $procol->find_iid($promote_to);
            
            unless ( $proobj ) {
                $log->error("Can not promote to non-existing thing");
                $self->do_error(444, { error_msg => "invalid promotion target" });
                return 0;
            }
        }
        else {
            $proobj = $procol->create_promotion($object, $req);
            unless ( $proobj ) {
                $log->error("Failed to create promotion target!");
                $self->do_error(444, { error_msg => "failed to create promotion target"});
                return 0;
            }
            $promote_to = $proobj->id;
        }

        my $lhref_a     = {
            type   => $object_type,
            id     => $object->id,
        };
        my $lhref_b     = {
            type => $proname,
            id   => $promote_to,
        };

        my $ret = $linkcol->create_bidi_link($lhref_a, $lhref_b);

        unless ( $ret ) {
            $log->error("Error creating Link: ",
                {filter=>\&Dumper, value=> [$lhref_a,$lhref_b]});
            $self->do_error(444, { error_msg => "failed to promote!" });
            return 0;
        }

        if ( ref($object) eq "Scot::Model::Alert" ) {
            $mongo->collection('Alertgroup')->refresh_data($object->alertgroup, $user);
        }
        try {
            $object->update({
                '$set'  => {
                    status  => 'promoted',
                    updated => $env->now(),
                }
            });
        }
        catch {
            $log->error("Failed update of promoted object");
        };

        $self->do_render({
            id      => $object->id,
            status  => "successfully promoted",
        });

        if ( $object->meta->does_role("Historable") ) {
            $mongo->collection('History')->add_history_entry({
                who     => $self->session('user'),
                what    => "$object_type promotion to $proname",
                when    => $env->now(),
                targets => { id => $object->id, type => $object_type },
            });
        }
    }
    else {
        $log->trace("Unpromoting object");

       $linkcol->remove_bidi_links({
            item_type   => $object_type,
            item_id     => $object->id,
            target_type => $proname,
            target_id   => $promote_to,
        });
        if ( ref($object) eq "Scot::Model::Alert" ) {
            $mongo->collection('Alertgroup')->refresh_data($object->alertgroup, $user);
        }
    }
    return 1;
}

sub get_value_from_request {
    my $self    = shift;
    my $req     = shift;
    my $attr    = shift;
    return $req->{request}->{params}->{$attr} // $req->{request}->{json}->{$attr};
}

sub write_promotion_history_notification {
    my $self    = shift;
    my $object  = shift;
    my $user    = shift;
    my $what    = shift;
    my $when    = $self->env->now;
    my $targets = shift;
    my $type    = shift // "update";
    my $mongo   = $self->env->mongo;

    if ( $object->meta->does_role("Historable") ) {
        $mongo->collection('History')->add_history_entry({
            who     => $user,
            what    => $what,
            when    => $when,
            targets => [ $targets ],
        });
    }
    $self->env->amq->send_amq_notification($type, $object, $user);
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

    if ( $key ne '' ) {
        delete $params->{$key};
        $params->{task} = {
            who     => $user,
            when    => $now,
            status  => $status,
        };
    }
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
    $self->env->log->error("Did not find Alertgroup ".$alert->alertgroup);
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


# one reason for this is how to handle actions on multi-clicked rows
# another, some things are hard to shoehorn into the REST paradigm. (e.g. send msg to queue )
sub do_command {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $user    = $self->session('user');

    $log->trace("------------");
    $log->trace("API is processing a PUT COMMAND request from $user");
    $log->trace("------------");

    my $req_href    = $self->get_request_params;

}

sub get_req_value {
    my $self    = shift;
    my $req     = shift;
    my $param   = shift;

    return $req->{request}->{param}->{$param} // $req->{request}->{json}->{$param};
}

# alertgroups are weird, and some analysts want to view multiple alerts from multiple alertgroups

sub supertable {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    $log->debug("Creating Supertable of Alertgroups");

    # tb assumes alertgroup=1&aplertgroup=2
    # rj assume alertgroup={alergroup:[1,2]}

    my $req_json    = $self->req->json;
    my $req_params  = $self->get_request_params; 

    $log->debug("req_params are: ",{filter=>\&Dumper,value=>$req_params});
    $log->debug("req_json   are: ",{filter=>\&Dumper,value=>$req_json});

    # We need to build an array of alertgroup ids that will search for in the
    # alert collection based on the values passed into either via the tb
    # or rj methods above

    my @alertgroup_ids  = ();

    if ( $req_json ) {
        my @json_ids    = @{$req_json->{alertgroup}};
        $log->debug("JSON ids are ",{filter=>\&Dumper, value=>\@json_ids});
        push @alertgroup_ids, @json_ids;
    }

    if ( $req_params->{request}->{params}->{alertgroup} ) {
        my @param_ids   = @{$req_params->{request}->{params}->{alertgroup}};
        $log->debug("PARAM ids are ", {filter=>\&Dumper, value=>\@param_ids});
        push @alertgroup_ids, @param_ids;
    }

    @alertgroup_ids = map { $_ + 0 } @alertgroup_ids;   # prevent strings

    $log->debug("alertgroup_ids are ", {filter=>\&Dumper, value=>\@alertgroup_ids});

    my %cols    = ();
    my @columns = (qw(when alertgroup));
    my @rows    = ();

    my $alertcol    = $mongo->collection('Alert');
    my $match_ref   = { alertgroup   => { '$in'  => \@alertgroup_ids } };
    my $cursor      = $alertcol->find($match_ref);

    while ( my $alert = $cursor->next ) {
        # $log->debug("Alert ", {filter=>\&Dumper, value=>$alert});

        my $href    = {
            when        => $alert->when,
            alertgroup  => $alert->alertgroup,
        };
        
        my $data    = $alert->data_with_flair // $alert->data;

        unless ($data) {
            $log->error("Alert has no data!");
        }

        foreach my $key (keys %$data) {
            $cols{$key}++;
            $href->{$key}   = $data->{$key};
        }
        push @rows, $href;
    }

    push @columns, sort keys %cols;

    $self->do_render({
        records             => \@rows,
        columns             => \@columns,
        queryRecordCount    => scalar(@rows),
        totalRecordCount    => scalar(@rows),
    });
}

sub build_match_ref {
    my $self	        = shift;
    my $filter_ref      = shift;     
    my $env   	        = $self->env;
    my $log             = $env->log;
    my $match           = {};
    my $store;
    my @datefields      = qw(updated created occurred discovered reported);
    my @numfields       = qw(views); 

    while (my ($k, $v)  = each %{$filter_ref}) {
	if($k =~ /id/) {
	    if(ref ($v) eq "ARRAY" ) {
		@$v = map {$_} @$v;
	        if(grep(m/!/, @$v) || grep(m/Not/i, @$v)) {
		    for(@$v){
		     s/\Not//gi;
	  	     s/\!//g;
		     s/\s+//;
		   }
		     @$store = map {$_ + 0} @$v;
		     $match->{$k}  = { '$nin' => $v};
		}
		else {
		      @$store = map {$_ + 0} @$v;
	              $match->{$k} = {'$in' => $v};
		  }
	       }
	   }
     elsif ( grep {/$k/}  @numfields){
	     @$v = map {$_} @$v;
	        if(grep(m/!/, @$v) || grep(m/Not/i, @$v)) {
		    for(@$v){
		     s/\Not//gi;
	  	     s/\!//g;
		     s/\s+//;
		   }
		     @$store = map {$_ + 0} @$v;
		     $match->{views}  = { '$nin' => $v};
		}
		else {
		      @$store = map {$_ + 0} @$v;
	              $match->{views} = {'$in' => $v};
		  }
	 }
     elsif($k eq "tags") {
	       $match->{$k}  = {'$all' => $v };
	 }	
	 elsif ( grep { /$k/ } @datefields ) {
              if($v =~ m/!/ || $v =~ m/Not/i) {
	  	  $v  =~ s/\!//g;
		  $v  =~ s/\Not//gi;
		  $v  =~ s/\s+//;
		  my $epoch_href = $v;
		  my $begin      = $epoch_href->{begin};
		  my $end        = $epoch_href->{end};
		     $match->{$k}   = { '$ne' => '$gte'  => $begin, '$lte' => $end };
	        }
		else {
	          my $epoch_href = $v;
		  my $begin      = $epoch_href->{begin};
		  my $end        = $epoch_href->{end};
		     $match->{$k}   = { '$gte'  => $begin, '$lte' => $end };
	        }
           }
	 else {
	      if($v =~ m/!/ || $v =~ m/Not/i) {
		    $v  =~ s/\!//g;
		    $v  =~ s/\Not//gi;
		    $v  =~ s/\s+//;
 		    $match->{$k} = {'$ne' => lc $v };
		}
	       else {
		  $match->{$k} = qr/$v/i;
	        }
	   }
      }
		
	return $match;
}
    

1;
