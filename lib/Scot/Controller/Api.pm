package Scot::Controller::Api;

use Carp qw(longmess);
use Data::Dumper;
use Data::Dumper::HTML qw(dumper_html);
use Data::UUID;
use Mojo::JSON qw(decode_json encode_json);
use Try::Tiny;
use Net::IP;
use Crypt::PBKDF2;
use Mail::Send;
use Mojo::UserAgent;
use strict;
use warnings;
use base 'Mojolicious::Controller';

=item B<create>

This function is called for POSTs to the API.  Data is passed in via
Mojolicious' handling of posted JSON and/or params. See 
get_request_params for further info.

It expects a JSON blob that matches the description of the model we are 
attempting to create.  See Scot::Model::* for details.

This function returns the following JSON to the http client
    {
        id      : the_integer_id_of_created_thing,
        action  : "post",
        thing   : model_name_of_created_thing,
        status  : 'ok',
    }

This function emits the following messages on the SCOT activemq topic:

    {
        action : "created",
        data   : {
            who     : "user_name",
            type    : "model_name_of_thing_created",
            id      : integer_id_of_thing_created
        }
    }

This function writes the following record to the history collection
    {
        who     => $user,
        what    => "created via api",
        when    => $self->env->now,
        target  => { 
            id      => $object->id,
            type    => $colname,
        }
    }

additionaly, if the object is targetable, the target object
will receive a similar history record.

This function creates the following record to the audit collection
    {
        who     => $self->session('user') // 'unknown',
        when    => $env->now(),
        what    => $what,
        data    => $data,
    }

=cut

sub create {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $user    = $self->session('user');

    $log->debug("CREATE");

    try {
        my $req_href    = $self->get_request_params;
        my $collection  = $self->get_collection_req($req_href);
        $req_href->{groups} = $self->session('groups');
        $self->pre_create_process($req_href);
        my @objects     = $collection->api_create($req_href);
        my @returnjson  = ();

        foreach my $object (@objects) {
            push @returnjson, $self->post_create_process($object);
            my $data = {
                who => $req_href->{user},
                type=> $object->get_collection_name,
                id  => $object->id,
            };
            if ( ref($object) eq "Scot::Model::Entry" ) {
                $data->{target} = $object->target;
            }
            $self->env->mq->send("/topic/scot",{
                action  => "created",
                data    => $data,
            });
        }
        if ( scalar(@returnjson) > 1 ) {
            $self->do_render(\@returnjson);
        }
        else {
            $self->do_render(pop @returnjson);
        }
    }
    catch {
        $log->error("In API create, Error: $_");
        $log->error(longmess);
        $self->render_error(400, { error_msg => $_ } );
    };
}

sub pre_create_process {
    my $self        = shift;
    my $req_href    = shift;
    my $req         = $req_href->{request};
    my $json        = $req->{json};
    my $collection  = $req_href->{collection};

    if ($collection eq "entitytype") {
        # place data cleansing here for creation of entitytype
        # clean both entity name and type
    }
}

sub post_create_process {
    my $self    = shift;
    my $object  = shift;
    my $objtype = ref($object);
    my $model   = lc((split(/::/,$objtype))[-1]);
    my $mongo   = $self->env->mongo;
    my $json        = {
        id      => $object->id,
        action  => "post",
        thing   => $model,
        status  => 'ok',
    };

    if ( ref($object) eq "Scot::Model::Entry" ) {
        $self->update_target($object, "create");
    }

    if ( ref($object) eq "Scot::Model::Sigbody" ) {
        $json->{revision} = $object->revision;
        $self->env->mq->send("/topic/scot", {
            action  => "updated",
            data    => {
                who     => $self->session('user'),
                type    => "signature",
                id      => $object->signature_id,
            }
        });
    }

    if ( $object->meta->does_role("Scot::Role::Tags") ) {
        $self->apply_tags($object);
    }

    if ( $object->meta->does_role("Scot::Role::Sources") ) {
        $self->apply_sources($object);
    }

    if ( $object->meta->does_role("Scot::Role::Historable") ) {
        $self->add_create_history($object);
    }

    $mongo->collection('Audit')->create_audit_rec({
        handler => $self, 
        object  => $object,
    });
    $mongo->collection('Stat')->put_stat(
        $object->get_collection_name." created", 1
    );

    if ( ref($object) eq "Alertgroup" ) {
        $mongo->collection('Stat')->put_stat(
            'alert created', $object->alert_count
        );
    }

    return $json;
}

sub add_create_history {
    my $self    = shift;
    my $object  = shift;
    my $colname = $object->get_collection_name;
    my $collection  = $self->env->mongo->collection('History');
    my $user    = $self->session('user');

    $collection->add_history_entry({
        who     => $user,
        what    => "created via api",
        when    => $self->env->now,
        target  => { 
            id      => $object->id,
            type    => $colname,
        }
    });
    # entries, mostly.  add history to target as well
    if ( $object->meta->does_role('Scot::Role::Target') ) {
        $collection->add_history_entry({
            who     => $user,
            what    => "$colname ". $object->id." added",
            when    => $self->env->now,
            target  => { 
                id      => $object->target->{id},
                type    => $object->target->{type},
            }
        });
    }
}

=item B<list>

This function is called for GETs to the API with out explicit ID provided.

It can have a JSON blob that specifies the "filter" to apply to the list
as well as sorting, limit, and offset parameters.  The user's group membership
also determines if anything is display, e.g.  unless the user has permission
to read an object it will not appear in the list (change from 3.5.1)

This function returns the following JSON to the http client
    {
        records : [
            { JSON object },
            ...
        ],
        queryRecordCount : number_of_rec_in_records_array,
        totalRecordCount : number_of_matching_in_entire_db,

    }

This function does not emit any messages on the SCOT topic in activemq

This function does not write any records to the history collection

This function does not create any record to the audit collection


=cut

sub get_groups {
    my $self    = shift;
    my $aref    = $self->session('groups');
    my @groups  = map { lc($_) } @{$aref};
    return wantarray ? @groups : \@groups;
}

sub list {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $user    = $self->session('user');
    my $groups  = $self->get_groups;

    $log->debug("LIST");

    try {
        my $req_href        = $self->get_request_params;
        my $collection      = $self->get_collection_req($req_href);
        my ($cursor,$count) = $collection->api_list($req_href, $user, $groups);
        $log->debug("list request return $count records");
        my @records         = $self->post_list_process( $cursor, $req_href);
        my $return_href = {
            records             => \@records,
            queryRecordCount    => scalar(@records),
            totalRecordCount    => $count,
        };
        $self->do_render($return_href);
    }
    catch {
        $log->error("in API list, Error: $_");
        $self->render_error(400, { error_msg => $_ } );
    };
}

sub post_list_process {
    my $self        = shift;
    my $cursor      = shift;
    my $req_href    = shift;
    my $log         = $self->env->log;
    my @records     = ();
    my $thing       = $req_href->{collection};
    my $entrycol    = $self->env->mongo->collection('Entry');

    if ( $thing      eq "event" ) {
        while ( my $obj = $cursor->next ) {
            my $href    = $obj->as_hash;
            $href->{has_tasks} = $entrycol->tasks_not_completed_count($obj);
            push @records, $href;
        }
    }
    elsif ( $thing      eq "entry" && $req_href->{task_search} ) {
        while ( my $obj = $cursor->next ) {
            my $href    = $obj->as_hash;
            my $target  = $href->{target};
            my $tobj;
            if ( ucfirst($target->{type}) eq "Alert" ) {
                my $aobj    = $self->env->mongo->collection(ucfirst($target->{type}))->find_iid($target->{id});
                my $agid    = $aobj->alertgroup;
                $tobj       = $self->env->mongo->collection('Alertgroup')->find_iid($agid);
            }
            else {
                $tobj    = $self->env->mongo->collection(ucfirst($target->{type}))->find_iid($target->{id});
            }
            my $subject = $tobj->subject // '';
            $href->{subject} = $subject;
            push @records, $href;
        }
    }
    elsif ( $thing      eq "alertgroup" ) {
        while ( my $obj = $cursor->next ) {
            my $agid = $obj->id;
            my $href = $obj->as_hash;
            $href->{has_tasks} = 0;
            my $acur = $self->env->mongo->collection('Alert')->find({alertgroup => $agid});
            ALERT:
            while ( my $aobj = $acur->next ) {
                my $tc = $entrycol->tasks_not_completed_count($aobj);
                if ( $tc > 0 ) {
                    $href->{has_tasks} = $tc;
                    last ALERT;
                }
            }
            push @records, $href;
        }
    }
    elsif ( $thing eq "alert" ) {
        $log->debug("post list proc of alert");
        while ( my $obj = $cursor->next ) {
            my $href    = $obj->as_hash;
            my $withsub = $req_href->{request}->{params}->{withsubject};
            if ( defined $withsub && $withsub == 1 ) {
                $log->debug("alertgroup subject requested");
                my $agid    = $href->{alertgroup};
                my $agobj   = $self->env->mongo->collection('Alertgroup')->find_iid($agid);
                $href->{subject}    = $agobj->subject // '';
                $log->debug("subject is ".$href->{subject});
            }
            push @records, $href;
        }
    }
    else {
        @records     = $cursor->all;
    }

    $log->debug("post_list_processing");

    my $collection  = $self->get_collection_req($req_href);

    # special case of the handler 
    if ( $collection eq "handler" ) {
        if (scalar(@records) < 1 ) {
            push @records, { username => 'unassigned' };
        }

        $self->do_render({
            records             => \@records,
            queryRecordCount    => 1,
            totalRecordCount    => 1,
        });
        $self->audit("get_current_handler", $req_href);
        return;
    }

    # remove any fields that are excluded
    foreach my $href (@records) {
        $self->filter_unrequested_columns($collection, $href, $req_href);
    }
    return wantarray ? @records : \@records;
}

=item B<get_one>

This function is called for GETs to the API with an id.

Special case: the id of "maxid" will return the maximum integer id for the
collection.

Assuming the user has read permission for the object they will get:
    {
        object_JSON_representation
    }

This function does not emit any messages on the SCOT topic in activemq

This function does not write any records to the history collection but
it will add a view record to the object itself.

This function creates the following record to the audit collection
    {
        who     => $self->session('user') // 'unknown',
        when    => $env->now(),
        what    => $what,
        data    => $request_href,
    }

This function creates a stat record for view count.

=cut


sub get_one {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("GET ONE");

    try {
        my $req_href        = $self->get_request_params;
        my $collection      = $self->get_collection_req($req_href);
        my $id              = $req_href->{id};

        # special case
        if ( $id eq "maxid" ) {
            $self->do_render({ 
                max_id      => $collection->get_max_id,
                collection  => $collection->get_collection_name,
            });
            return;
        }

        my $object  = $collection->api_find($req_href);
        if (! defined $object ) {
            die "Object not found";
        }
        my $objhref = $self->post_get_one_process($object, $req_href);

        # special case for file downloads or pushes
        if ( ref($object) eq "Scot::Model::File" ) {
            my $download    = $self->param('download');
            if ( defined $download ) {
                $self->download_file($object);
                return;
            }
            # future push actions through the server instead of in the client
            #my $push        = $self->param('push');
            #if ( defined $push ) {
            #    $self->push_file($object, $req_href);
            #    return;
            #}
        }
        $self->do_render($objhref);
    }
    catch {
        $log->error("in API get_one, Error: $_");
        my $code    = 400;
        if ( $_ =~ /Object not found/ ) {
            $code = 404;
        }
        $self->render_error($code, { error_msg => $_ });
    };
}

sub post_get_one_process {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $env     = $self->env;

    # handle special get_one cases and convert object into hash

    if ( $object->meta->does_role('Scot::Role::Permittable') ) {
        unless ( $object->is_readable($self->get_groups) ) {
            $self->read_not_permitted_error;
            die "Read not permitted";
        }
    }

    if ( $object->meta->does_role('Scot::Role::Views') ) {
        my $from_ip = $self->tx->remote_address;
        my $user    = $self->session('user');
        if ( $user ne "scot-alerts" ) {
            $object->add_view($user, $from_ip, $self->env->now);
        }
    }

    if ( ref($object) eq "Scot::Model::File" ) {
        # special handling for file downloads
        my $download    = $self->param('download');
        if (defined $download) {
            return $self->download_file($object);
        }
    }

    if ( ref($object) eq "Scot::Model::Entity" ) {
        # do entity enrichment refresh
        $self->refresh_entity_enrichments($object);
    }

    my $href    = $object->as_hash;

    my $alertcol    = $self->env->mongo->collection('Alertgroup');
    if ( ref($object) eq "Scot::Model::Alert" ) {
        # add in subject from alertgroup
        $href->{subject} = $alertcol->get_subject($object->alertgroup);
        # count alerts
    }

    if ( ref($object) eq "Scot::Model::Alertgroup" ) {
        $href->{alerts} = $alertcol->get_alerts_in_alertgroup($object);
        $href->{alert_count} = scalar(@{$href->{alerts}});
        if ( $object->firstview == -1 ) {
            $object->update_set(firstview => $self->env->now);
        }
    }

    if ( ref($object) eq "Scot::Model::Signature" ) {
        my $signaturecol = $self->env->mongo->collection('Signature');
        $href->{version} = $signaturecol->get_sigbodies($object);
    }

    #if ( defined $env->forms->{$object->get_collection_name} ) {
    #    my @elements = $env->forms->{$object->get_collecton_name};
    #    my @form     = ();
    #    foreach my $fhref (@elements) {
    #        my $compute = $href->{computed};
    #        if ( defined $compute ) {
    #            $fhref->{value} = &compute($env, $object);
    #        }
    #        push @form, $fhref;
    #    }
    #    $href->{form} = \@form;
    #}

    $self->filter_unrequested_columns($alertcol, $href, $req);
    return $href;
}

sub filter_unrequested_columns {
    my $self    = shift;
    my $col     = shift;
    my $href    = shift;
    my $req     = shift;

    # since operating on reference href, this operates as a side effect.

    # eliminate unrequested fields.  We could move this up and check
    # columns for the enriched columns above as an optimization but
    # this really isn't slow in practice
    # limit_fields is in Collection.pm so we can use any collection ref
    my $cutfields   = $col->limit_fields($href, $req);
    if ( defined $cutfields ) {
        foreach my $key (keys %$href) {
            if ( ! defined $cutfields->{$key} ) {
                delete $href->{$key};
            }
        }
    }
}

sub refresh_entity_enrichments {
    my $self            = shift;
    my $entity          = shift;
    my ($updated, $data) = $self->env->enrichments->enrich($entity);

    if ( $updated > 0 ) {
        foreach my $key (keys %$data) {
            $entity->update_set("data.$key" => $data->{$key});
        }
    }
    else {
        $self->env->log->debug('No entity updates');
    }
}

sub download_file {
    my $self    = shift;
    my $object  = shift;
    $self->res->content->headers->header(
        'Content-Type','application/x-download; name="'.$object->filename.'"');
    $self->res->content->headers->header(
        'Content-Disposition', 'attachment; filename="'.$object->filename.'"');
    my $static = Mojolicious::Static->new(paths => [ $object->directory ]);
    $static->serve($self, $object->filename);
    $self->rendered;
    return;
}

# not used since pushes to sarlacc can have an apikey in client from entry_actions in config
# keeping here for future use, potentially.
sub push_file {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $json    = $req->{request}->{json};
    my $send_name   = $json->{send_to_name};
    my $send_url    = $json->{send_to_url};
    my $apikey      = $$self->env->apikey->{$send_name};
    $send_url .= "&".$apikey;

    my $ua = Mojo::UserAgent->new();
    my $tx = $ua->post($send_url);
    my $response = $tx->success;

    if ( defined $response ) {
        return $response->json;
    }
    die "Failed File Push to $send_url, Error: ".$tx->error->{code}." ".$tx->error->{message};
}

=item B<get_subthing>

This function is called for GETs to the API for objects related to 
a given :thing :id, e.g.  /scot/api/v2/alergroup/123/alert will return
an array of alerts that are part of alertgroup 123.

It can have a JSON blob that specifies the "filter" to apply to the list
as well as sorting, limit, and offset parameters.  The user's group membership
also determines if anything is display, e.g.  unless the user has permission
to read an object it will not appear in the list (change from 3.5.1)

This function returns the following JSON to the http client
    {
        records : [
            { JSON object },
            ...
        ],
        queryRecordCount : number_of_rec_in_records_array,
        totalRecordCount : number_of_matching_in_entire_db,

    }

This function does not emit any messages on the SCOT topic in activemq

This function does not write any records to the history collection

This function does not create any record to the audit collection

=cut

sub get_subthing {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    $log->debug("GET SUBTHING");

    try {
        my $req_href        = $self->get_request_params;
        my $thing           = $req_href->{collection};
        my $subcollection   = $req_href->{subthing};
        my $id              = $req_href->{id};


        my $collection  = $mongo->collection(ucfirst($thing));
        my $cursor      = $collection->api_subthing($req_href);
        my $records     = $self->post_subthing_process(
            $collection, $req_href, $cursor
        );

        my $count = 0;
        if ( ref ($records) eq "HASH" ) {
            $count  = scalar(keys %$records);
        }
        if ( ref ($records) eq "ARRAY" ) {
            $count  = scalar(@$records);
        }

        $self->do_render({
            records => $records,
            queryRecordCount    => $count,
            totalRecordCount    => $count,
        });
    }
    catch {
        $log->error("in API get_subthing, Error: $_");
        $self->render_error(400, { error_msg => $_ });
    };
}

sub post_subthing_process {
    my $self        = shift;
    my $collection  = shift;
    my $req_href    = shift;
    my $cursor      = shift;
    my $subthing    = $req_href->{subthing};
    my $log         = $self->env->log;

    if ( $subthing eq "entry" ) {
        my @records    = $self->thread_entries($cursor);
        return \@records;
    }

    if ( $subthing eq "entity" ) {
        my %entities    = $self->process_entities($cursor);
        return \%entities;
    }

    my @records = $cursor->all;

    # $log->debug("records prior to filtering: ",{filter=>\&Dumper, value=>\@records});

    foreach my $href (@records) {
        $collection->filter_fields($req_href, $href);
    }
    return \@records;
}



=item B<update>

This function is called for POSTs to the API with an id.

Assuming the user has modify permission for the object they will get:
    {
        id : int_id_of_object_updated,
        status : "ok"
    }

This function emits messages on the SCOT topic in activemq
    {
        action : "updated",
        data   : {
            who : username,
            type : collection_name,
            id : id updated,
            what : [ things, that, were, done ]
        }
    }
and messages for the target objects if updated object is targetable.

This function does write records to the history collection 

This function creates the following record to the audit collection
    {
        who     => $self->session('user') // 'unknown',
        when    => $env->now(),
        what    => $what,
        data    => $request_href,
    }

This function creates a stat record for "$collection updated"

=cut

sub update {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("UPDATE");

    try {
        my $req_href    = $self->get_request_params;

        
        my $collection  = $self->get_collection_req($req_href);
        if ($self->id_is_invalid($req_href)) { 
            die "Invalid id"; 
        }
        my $object  = $collection->api_find($req_href);
        if ( ! $self->update_permitted($object, $req_href)) { 
            die "Insufficent Privilege"; 
        }
        # special case of undelete
        if ( $req_href->{request}->{json}->{status} eq "undelete" ) {
            return $self->undelete($object, $req_href);
        }
        # special case of promotion
        if ( defined $req_href->{request}->{json}->{promote} ) {
            return $self->promote($object, $req_href);
        }
        $self->pre_update_process($object, $req_href);
        my @updates = $collection->api_update($object, $req_href);
        $self->post_update_process($object, $req_href, \@updates);
        $self->do_render({id => $object->id, status => 'ok'});
    }
    catch {
        $log->error("in API update, Error: $_");
        my $code = 400;
        if ( $_ =~ /Insufficent Privilege/ ) {
            $code = 403;
        }
        $self->render_error($code, { error_msg => $_ });
    };
}


sub update_permitted {
    my $self    = shift;  
    my $object  = shift;    
    my $req     = shift;
    my $env     = $self->env;

    ## 
    ## Permission has the groups that are allowd to modify
    ## 
    if ( $object->meta->does_role('Scot::Role::Permission') ) {
        my $group_aref  = $self->get_groups;
        return $object->is_modifiable($group_aref);
    }

    ##
    ## Admin's can modify all
    ## but a user can only modify their password and Full name
    ## 
    if ( ref($object) eq "Scot::Model::User" ) {
        if ( $env->is_admin($self->session('user'),$self->session('groups')) ) {
            return 1;
        }
        if ( $req->{request}->{username} eq $self->session('user') ) {
            delete $req->{request}->{active};
            delete $req->{request}->{groups};
            delete $req->{request}->{username};
            return 1;
        }
        return undef;
    }
    ##
    ## Admin's can modify all
    ## but a user can not do it 
    ## 
    if ( ref($object) eq "Scot::Model::Group" ) {
        if ( $env->is_admin($self->session('user'),$self->session('groups'))) {
            return 1;
        }
        return undef;
    }
    return 1;
}


sub pre_update_process {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    $log->debug("PRE UPDATE");

    # my $usersgroups = $self->session('groups');
    my $usersgroups  = $self->get_groups;

    if ( ref($object) eq "Scot::Model::Apikey" ) {
        my $updated_groups = [];
        foreach my $g ($req->{groups}) {
            if ( grep {/$g/} @$usersgroups ) {
                push @$updated_groups, $g;
            }
        }
        $req->{groups} = $updated_groups;
    }

    if ( ref($object) eq "Scot::Model::User" ) {
        # del password and create pwhash
        my $pass_input  = delete $req->{request}->{json}->{password};
        if ( defined $pass_input ) {
            my $pbkdf2      = Crypt::PBKDF2->new(
                hash_class  => 'HMACSHA2',
                hash_args   => { sha_size => 512 },
                iterations  => 10000,
                salt_len    => 15,
            );
            my $pwhash  = $pbkdf2->generate($pass_input);
            $req->{request}->{json}->{pwhash} = $pwhash;
        }
    }

    if ( ref($object) eq "Scot::Model::Alertgroup" ) {
        $self->update_alerts($object,$req);
        delete $req->{request}->{json}->{status}; # set by above function
    }

    if ( ref($object) eq "Scot::Model::Entry" ) {
        $self->process_task_commands($object, $req);
    }

    if ( $object->meta->does_role("Scot::Role::Entitiable") ) {
        $log->debug("object is entitiable");
        my $entity_aref = delete $req->{request}->{json}->{entities};
        $log->debug("entities aref is ",{filter=>\&Dumper, value=>$entity_aref});
        my $collection  = $self->env->mongo->collection('Entity');
        $collection->update_entities($object, $entity_aref);
    }
    
    # if the object does tags or source, we need to adjust the appearances collection
    # to reflect the changes, because we store tags/sources as an array in the object
    # and create appearance records 

    if ( $object->meta->does_role("Scot::Role::Tags") or
         $object->meta->does_role("Scot::Role::Sources") ) {

        my $new_tag_set = $req->{request}->{json}->{tag};
        my $new_src_set = $req->{request}->{json}->{source};

        if (defined $new_tag_set ) {
            $mongo->collection('Appearance')
                   ->adjust_appearances($object,$new_tag_set,"tag");
        }
        if (defined $new_src_set ) {
            $mongo->collection('Appearance')
                   ->adjust_appearances($object,$new_src_set,"source");
        }
    }
}

sub get_promotion_collection {
    my $self    = shift;
    my $object  = shift;
    my $mongo   = $self->env->mongo;

    if ( ref($object) eq "Scot::Model::Alert" ) {
        return $mongo->collection('Event');
    }
    if ( ref($object) eq "Scot::Model::Event" ) {
        return $mongo->collection('Incident');
    }
    die "invalid promotion attempt";
}

# this function replaces the update function for promotions
sub promote {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $user    = $self->session('user');

    $log->debug("processing promotion");

    # find or create the promotion target
    my $promotion_col;
    if ( ref($object) eq "Scot::Model::Alert" ) {
        $promotion_col  = $mongo->collection("Event");
    }
    elsif ( ref($object) eq "Scot::Model::Event" ) {
        $promotion_col  = $mongo->collection("Incident");
    }
    else {
        die "Unable to promote a ".ref($object);
    }

    my $promotion_obj = $promotion_col->get_promotion_obj($object,$req);
    $promotion_obj->update({
        '$addToSet' => { promoted_from => $object->id }
    });

    if ( ref($object) eq "Scot::Model::Alert") {
        $mongo->collection('Alertgroup')->refresh_data($object->alertgroup);
        my $entry = $mongo->collection('Entry')
                          ->create_from_promoted_alert($object, $promotion_obj);
        $self->env->mq->send("/topic/scot",{
            action  => "created",
            data    => {
                who => $req->{user},
                type=> "entry",
                id  => $entry->id,
            }
        });

##      use this to memorialize the likaboss object
    if ( $env->meta->has_attribute('lbwebservice') ) {
        foreach my $rootuid (@{$object->data->{rootUID}}) {
            $log->debug("memorializing $rootuid");
            $self->env->lbwebservice->memorialize($rootuid);
        }
    }

    }

    # update the promotee
    $object->update({
        '$set'  => {
            updated         => $env->now,
            promotion_id    => $promotion_obj->id,
            status          => "promoted",
        }
    });

    $mongo->collection('Link')->link_objects($object,$promotion_obj,{
        context => "promotion"
    });


    # update mq and other bookkeeping
    $env->mq->send("/topic/scot", {
        action  => "created",
        data    => {
            who     => $user,
            type    => $promotion_obj->get_collection_name,
            id      => $promotion_obj->id,
        }
    });
    my $type = $object->get_collection_name;
    my $id   = $object->id;
    if ( $type eq "alert" ) {
        $env->mq->send("/topic/scot", {
            action  => "updated",
            data    => {
                who     => $user,
                type    => "Alertgroup",
                id      => $object->alertgroup,
                opts    => "noreflair",
            }
        });
    }
    else {
        $env->mq->send("/topic/scot", {
            action  => "updated",
            data    => {
                who     => $user,
                type    => $type,
                id      => $id,
            }
        });
    }

    my $what = $object->get_collection_name." promoted to ".
                       $promotion_obj->get_collection_name;
    if ( $object->meta->does_role("Scot::Role::Historable") ) {
        $mongo->collection('History')->add_history_entry({
            who     => $user,
            what    => $what,
            when    => $env->now,
            target  => {id => $object->id, type => $object->get_collection_name},
        });
    }

    $mongo->collection('Audit')->create_audit_rec({
        handler => $self,
        object  => $object,
        changes => $what,
        who     => $user,
    });

    # add stat here
    $self->env->mongo->collection('Stat')->put_stat(
        $object->get_collection_name." promoted", 1
    );

    # render and return
    $self->do_render({
        id      => $object->id,
        pid     => $promotion_obj->id,
        status  => "ok",
    });
}


sub update_alerts {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Alertgroup');
    my $status  = $col->update_alerts_in_alertgroup($object, $req);
    if ( scalar(@{$status->{updated}}) > 0 ) {
        foreach my $aid (@{$status->{updated}}) {
            $self->env->mq->send("/topic/scot",{
                action  => "updated",
                data    => {
                    who => $self->session('user'),
                    type=> "alert",
                    id  => $aid,
                }
            });
        }
    }
}

sub process_task_commands {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $json    = $req->{request}->{json};
    my $action  = '';
    my $status  = '';

    ## relies on side effect, 
    ## we are modifying the req_href in place based on task data

    if ( defined $json->{make_task} ) {
        $action         = "make_task";
        $json->{class}  = 'task';
        $status         = "open";
    }
    elsif ( defined $json->{take_task} ) {
        $action         = "take_task";
        $status         = "assigned";
    }
    elsif ( defined $json->{close_task} ) {
        $action         = "close_task";
        $status         = "closed";
    }
    

    if ( $action ne '' ) {
        delete $json->{$action}; # not an attribute in model
        $json->{metadata}   = {  # but this is
            task    => {
                who     => $self->session('user'),
                when    => $self->env->now,
                status  => $status,
            },
        };
        $self->env->mongo->collection('Stat')->put_stat(
            "task $status", 1
        );
    }
}

sub post_update_process {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $updates = shift; # aref of { what =>  , attribute=> ,old_value, new_value}
    my $env     = $self->env;
    my $colname = lc((split(/::/,ref($object)))[-1]);

    my $agcol   = $env->mongo->collection('Alertgroup');


    foreach my $uphref (@$updates) {
        if ( $uphref->{attribute} eq "status" ) {
            my $msg = "$colname status change to ". $uphref->{new_value};
            $env->mongo->collection('Stat')->put_stat($msg,1);
            $self->add_history($msg, $object);
        }
        if ( $uphref->{attribute} eq "target" ) {
            if ( ref($object) eq "Scot::Model::Entry" ) {
                $self->env->log->debug("processing entry move");
                $self->process_entry_moves($object, $req);
            }
        }
        $self->create_change_audit($object, $uphref);
        if ( ref($object) eq "Alert" ) {
            # need to write history to Alertgroup
            my $agobj = $agcol->find($object->alertgroup);
            if (defined $agobj) {
                $self->crete_change_audit($agobj, $uphref);
            }
        }
    }

    if ( $object->meta->does_role("Scot::Role::Tags") ) {
        $self->apply_tags($object);
    }

    if ( $object->meta->does_role("Scot::Role::Sources") ) {
        $self->apply_sources($object);
    }

    my $mqdata  = {
        who     => $self->session('user'),
        type    => $colname,
        id      => $object->id,
        what    => $self->changed_attributes($updates),
    };

    my $mq_msg  = {
        action  => "updated",
        data    => $mqdata,
    };

    $env->mq->send("/topic/scot", $mq_msg);

    if ( ref($object) eq "Scot::Model::Entry" ) {
        $mq_msg->{data} = {
            who     => $self->session('user'),
            target  => { type => $object->target->{type},
                         id   => $object->target->{id}, },
            what    => "Entry update",
        };
        $env->mq->send("/topic/scot", $mq_msg);
        $self->add_history("updated entry ".$object->id, $object);
    }

    if ( ref($object) eq "Scot::Model::Sigbody" ) {
        $mq_msg->{data} = {
            who     => $self->session('user'),
            type    => "signature",
            id      => $object->{signature_id},
            what    => "Signature Update",
        };
        $env->mq->send("/topic/scot", $mq_msg);
    }
    $env->mongo->collection('Stat')->put_stat("$colname updated", 1);
}

sub process_entry_moves {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $target  = $req->{target};

    $self->env->mongo->collection('Entry')->move_entry($object,$target);
}

sub process_entities {
    my $self    = shift;
    my $cursor  = shift;
    my %things  = ();
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    $log->debug("PROCESSING ENTITIES ".$cursor->count);

    while ( my $entity = $cursor->next ) {

        $log->debug("    entity = ".$entity->value);

        my $entry_cursor        = $mongo->collection('Entry')->get_entries(
            target_id   => $entity->id,
            target_type => 'entity',
        );
        my @threaded_entries    = $self->thread_entries($entry_cursor);

        $log->debug("    has ".scalar(@threaded_entries)." entries");

        my $appearance_count    = $self->get_entity_count($entity);

        $log->debug("    has $appearance_count appearances in scot");

        my $entry_count     = $self->get_entry_count($entity);

        $log->debug("    has $entry_count entries ");

        $things{$entity->value} = {
            id      => $entity->id,
            count   => $appearance_count,
            entry   => $entry_count,
            type    => $entity->type,
            classes => $entity->classes,
            data    => $entity->data,
            status  => $entity->status,
            entries => \@threaded_entries,
        };
        $log->debug("thing{".$entity->value."} = ",
                    {filter=>\&Dumper, value=>$things{$entity->value}});

    }
    $log->debug("done processing entities");
    return wantarray ? %things : \%things;
}

sub get_entity_count {
    my $self    = shift;
    my $entity  = shift;
    my $mongo   = $self->env->mongo;
    return $mongo->collection('Link')->get_display_count($entity);
}

sub get_entry_count {
    my $self    = shift;
    my $entity  = shift;
    my $mongo   = $self->env->mongo;
    return $mongo->collection('Entry')->get_entries(
        target_id   => $entity->id,
        target_type => 'entity',
    )->count;
}

sub changed_attributes {
    my $self    = shift;
    my $aref    = shift;
    my @changes = map { $_->{attribute}; } @$aref;
    return \@changes;
}

sub create_change_audit {
    my $self    = shift;
    my $object  = shift;
    my $href    = shift;
    my $name    = $object->get_collection_name;

    my $auditcol    = $self->env->mongo->collection('Audit');
    my $what    = $href->{attribute} . " updated";
    my $record      = $auditcol->create_audit_rec({
        handler => $self,
        object  => $object,
        changes => {
            old => $href->{old_value},
            new => $href->{new_value},
        }
    });
}

sub apply_tags {
    my $self    = shift;
    my $object  = shift;
    my $thing   = $object->get_collection_name;
    my $id      = $object->id;
    my $tagcol  = $self->env->mongo->collection('Tag');
    $tagcol->add_tag_to($thing, $id, $object->tag);
}

sub apply_sources {
    my $self    = shift;
    my $object  = shift;
    my $thing   = $object->get_collection_name;
    my $id      = $object->id;
    my $srccol  = $self->env->mongo->collection('Source');
    $srccol->add_source_to($thing, $id, $object->source);
}

sub update_target {
    my $self        = shift;
    my $object      = shift;
    my $update_type = shift;
    my $mongo       = $self->env->mongo;
    my $target      = $mongo->collection(
        ucfirst($object->target->{type})
    )->find_iid($object->target->{id});

    $self->env->log->debug("updating target ",{filter=>\&Dumper, value=>$object->target});

    my $tmphref = $target->as_hash;
#    $self->env->log->debug("found target       = ",{filter=>\&Dumper, value=>$tmphref});
#    $self->env->log->debug("updating type      = $update_type");
#    $self->env->log->debug("target entry_count = ".$target->entry_count);

    if ( defined $target ) {
        my $updated = 0;
        if ( $target->meta->does_role("Scot::Role::Entriable") ) {
            if ( $update_type eq "create" ) {
                $target->update_inc(entry_count => 1);
                $updated++;
            }
            if ( $update_type eq "delete" ) {
                $target->update_inc(entry_count => -1);
                $updated++;
            }
           #$self->env->log->debug("target entry_count = ".$target->entry_count);
        }
        if ( $target->meta->does_role("Scot::Role::Times") ) {
            $target->update_set(updated => $self->env->now);
            $updated++;
        }
        if ($updated > 0) {
            $self->mq_obj_update($target);
        }
        $self->env->log->debug("target entry_count = ". $target->entry_count);
    }
    else {
        $self->env->log->error("Failed to find target object to update");
    }
}

=item B<delete>

This function is called for DELETEs to the API.  you can only delete by id.

This function returns the following JSON to the http client
    {
        id      : the_integer_id_of_created_thing,
        action  : "delete",
        thing   : model_name_of_created_thing,
        status  : 'ok',
    }

This function emits the following messages on the SCOT activemq topic:

    {
        action : "deleted",
        data   : {
            who     : "user_name",
            type    : "model_name_of_thing_created",
            id      : integer_id_of_thing_created
        }
    }

This function writes the following record to the history collection
    {
        who     => $user,
        what    => "deleted via api",
        when    => $self->env->now,
        target  => { 
            id      => $object->id,
            type    => $colname,
        }
    }

additionaly, if the object is targetable, the target object
will receive a similar history record.

This function creates the following record to the audit collection
    {
        who     => $self->session('user') // 'unknown',
        when    => $env->now(),
        what    => $what,
        data    => $data,
    }

=cut

sub delete {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("DELETE");

    try {
        my $req_href    = $self->get_request_params;
        my $collection  = $self->get_collection_req($req_href);

        $log->debug("request is ",{filter=>\&Dumper, value=>$req_href});

        my $object;
        if (defined $req_href->{request}->{json}->{vertices}) {
            $log->debug("Deleting Link by vertices");
            # this will occurr during a delink operation
            # json will be {vertices:[ {id:a,type:x},{id:b,type:y} ]}
            my ($a,$b)  = @{$req_href->{request}->{json}->{vertices}};

            if ( defined $a and defined $b and ref($a) eq "HASH" and ref($b) eq "HASH" ) {
                my $match   = {
                    vertices    => {
                        '$all'  => [
                            { '$elemMatch'  => $a },
                            { '$elemMatch'  => $b },
                        ]
                    }
                };
                $log->debug("looking for link matching: ",{filter=>\&Dumper, value=>$match});
                $object = $collection->find_one($match);
            }
        }
        else {
            if ($self->id_is_invalid($req_href)) { 
                die "Invalid id"; 
            }
            my $id          = $req_href->{id};
            $object      = $collection->find_iid($id);
        }

        if ( ! defined $object ) {
            die "Object Not Found";
        }
        if ( $self->delete_not_permitted($object) ) {
            die "Insufficent Privilege";
        }
        $self->delete_or_purge($object, $req_href);
        $self->post_delete_process($object, $req_href);
        $self->do_render({id => $object->id, status => 'ok'});
    }
    catch {
        $log->error("in API delete, Error: $_");
        $self->render_error(400, { error_msg => $_ } );
    };
}

sub post_delete_process {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    my $mqdata  = {
        type    => $object->get_collection_name,
        id      => $object->id,
        who     => $self->session('user'),
    };

    if ( $object->meta->does_role('Scot::Role::Target') ) {
        $self->update_target($object, "delete");
        $mqdata->{target} = $object->target;
    }

    if ( ref($object) eq 'Scot::Model::Entry' ) {

        # may need to point children entries
        my $entrycol = $mongo->collection('Entry');
        my $cursor   = $entrycol->find({parent_id => $object->id});
        while ( my $child = $cursor->next ) {
            $child->update_set( parent_id => $object->parent_id );
        }
    }
    my $audit_rec = {
        handler => $self,
        object  => $object,
        who     => $self->session('user'),
    };
    $self->env->mq->send("/topic/scot",{
        action  => "deleted",
        data    => $mqdata,
    });
    $self->env->mongo->collection('Audit')->create_audit_rec($audit_rec);
    $self->env->mongo->collection('Stat')->put_stat($object->get_collection_name." deleted", 1);
}

sub delete_or_purge {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $params  = $req->{request}->{param};
    my $json    = $req->{request}->{json};
    my $purge   = $params->{purge} // $params->{purge};

    if ( ! defined $purge ) {
        # save copy to trashcan
        my $del_col = $self->env->mongo->collection('Deleted');
        $del_col->preserve($object);
    }
    $object->remove;
}

sub delete_not_permitted {
    my $self    = shift;
    my $object  = shift;
    my $users_groups    = $self->get_groups;

    if ($object->meta->does_role('Scot::Role::Permittable')) {
        if ( $object->is_modifiable($users_groups) ) {
            return undef;
        }
        $self->modify_not_permitted_error($object, $users_groups);
        return 1;
    }
    return undef;
}

sub id_is_invalid {
    my $self    = shift;
    my $href    = shift;
    my $id      = $href->{id};
    if ($id =~ /^\d+$/) {
        return undef;
    }
    return 1;
}


sub mq_obj_update {
    my $self    = shift;
    my $target  = shift;
    my $mq      = $self->env->mq;

    $mq->send("/topic/scot", {
        action  => "updated",
        data    => {
            who     => $self->session('user'),
            type    => $target->get_collection_name,
            id      => $target->id,
        }
    });
}

sub add_history {
    my $self        = shift;
    my $message     = shift;
    my $object      = shift;
    my $colname     = $object->get_collection_name;
    my $collection  = $self->env->mongo->collection('History');
    my $user        = $self->session('user');

    $collection->add_history_entry({
        who     => $user,
        what    => $message,
        when    => $self->env->now,
        target  => { id => $object->id, type => $colname },
    });
}
    

sub get_collection_req {
    my $self        = shift;
    my $req_href    = shift;
    my $log         = $self->env->log;
    my $thing       = $req_href->{collection};
    my $colname     = ucfirst($thing);
    my $mongo       = $self->env->mongo;

    if ( ! defined $colname ) {
        die "Undefined Collection Name";
    }

    my $collection = $mongo->collection($colname);

    if ( defined $collection ) {
        return $collection;
    }
    die "Failed to get Collection object";
}

sub get_request_params  {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $mreq    = $self->req;
    $log->trace("mojolicious request obj: ",{filter=>\&Dumper, value=>$mreq});

    my $params  = $self->req->params->to_hash;
    my $json    = $self->req->json;

    $log->trace("params => ", { filter => \&Dumper, value => $params });
    $log->trace("json   => ", { filter => \&Dumper, value => $json });

    if ( $params ) {
        $log->trace("Checking Params for JSON values");
        foreach my $key (keys %{$params}) {

            $log->trace("param ". Dumper($key) ." = ", 
                        {filter=>\&Dumper, value => $params->{$key}});

            my $parsedjson;
            try {
                $parsedjson = decode_json($params->{$key});
            }
            catch {
                $log->debug("no json detected, keeping data...");
                $parsedjson = $params->{$key}; # not really json!
            };
            $params->{$key} = $parsedjson;
        }
    }

    $log->trace("building request href");
    my %request = (
        collection  => $self->stash('thing'),
        id          => $self->stash('id'),
        subthing    => $self->stash('subthing'),
        subid       => $self->stash('subid'),
        user        => $self->session('user'),
        request     => {
            params  => $params,
            json    => $json,
        },
    );
    if ( $request{collection} eq "task" ) {
        $request{collection} = "entry";
        $request{task_search} = 1;
    }
    $log->debug("Request is ",{ filter => \&Dumper, value => \%request } );
    return wantarray ? %request : \%request;
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

sub render_error {
    my $self    = shift;
    my $code    = shift;
    my $href    = shift;
    $self->render(
        status  => $code,
        json    => $href,
    );
}

sub thread_entries {
    my $self    = shift;
    my $cursor  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mygroups    = $self->get_groups;
    my $user        = $self->session('user');

    $log->debug("Threading ". $cursor->count . " entries...");
    $log->debug("users groups are: ", {filter=>\&Dumper, value=>$mygroups});

    my @threaded    = ();
    my %where       = ();
    my $rindex      = 0;
    my $sindex      = 0;
    my $count       = 1;
    my @summaries   = ();

    $cursor->sort({id => 1});

    ENTRY:
    while ( my $entry   = $cursor->next ) {

        # do not thread (include) entries not viewable by user
        unless ( $entry->is_readable($mygroups) ) {
            $log->debug("Entry ".$entry->id." is not readable by $user");
            next ENTRY;
        }

        $count++;
        my $href            = $entry->as_hash;
        if ( ! defined $href->{children} ) {
            $href->{children}   = [];   # create holder for children
        }

        if ( ref($href->{children}) ne "ARRAY" ) {
            $href->{children}   = [];   # create holder for children
        }

        if ( $entry->class eq "summary" ) {
            $log->trace("entry is summary");
            push @summaries, $href;
            $where{$entry->id} = \$summaries[$sindex];
            $sindex++;
            next ENTRY;
        }

        if ( $href->{body} =~ /class=\"fileinfo\"/ ) {
            # we have a file entry so we need to "enrich" the data
            # so that the UI can build sendto buttons
            # actions defined in the config file
            if ( defined $self->env->{entry_actions}->{fileinfo} ) {
                my $action  = $env->{entry_actions}->{fileinfo};
                my $servername = `hostname`;
                chomp($servername);
                $log->debug("SERVERNAME is $servername");
                $href->{actions} = [ $action->($href,$servername) ];
            }
        }

        if ( $entry->parent == 0 ) {
            # add this href to threaded array
            $threaded[$rindex]  = $href;
            # store a link to this entry based on the entry id
            $where{$entry->id}  = \$threaded[$rindex];
            # incr the index
            $rindex++;
            next ENTRY;
        }

        $log->debug("Entry ".$entry->id." is a child entry to ".$entry->parent);

        # get the parent href
        my $parent_ref          = $where{$entry->parent};
        # get the array ref within the parent
        my $parent_kids_aref    = $$parent_ref->{children};
        $log->trace("parents children: ",{filter=>\&Dumper, value => $parent_kids_aref});
        my $child_count         = 0;

        if ( defined $parent_kids_aref ) {
            $child_count    = scalar(@{$parent_kids_aref});
            $log->debug("Parent has $child_count children");
        }

        my $new_child_index = $child_count;
        $log->debug("The parent has $child_count children");
        $parent_kids_aref->[$new_child_index]  = $href;
        $log->debug("added entry to parents aref");
        $log->debug("parents children: ",{filter=>\&Dumper, value => $parent_kids_aref});
        $where{$entry->id} = \$parent_kids_aref->[$new_child_index];
    }

    unshift @threaded, @summaries;

    $log->debug("ready to return threaded entries");

    return wantarray ? @threaded : \@threaded;
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

# TODO
    $env->mq->send("/topic/scot", {
        action  => "message",
        data    => {
            wall    => ""
        }
    });
}

sub wall { 
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $user    = $self->session('user');
    my $msg     = $self->param('msg');
    my $now     = $env->now;

    $env->mq->send("/topic/scot", {
        action  => "wall",
        data    => {
            message => $msg,
            who     => $user,
            when    => $now,
        }
    });
    $self->do_render({
        action  => 'wall',
        status  => 'ok',
    });
}

sub autocomplete {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $thing   = $self->stash('thing');
    my $fragment = $self->stash('search');

    $log->debug("Autocompleting $thing against $fragment fragment");

    try {
        my @values  = $mongo->collection(ucfirst($thing))
                            ->autocomplete($fragment);
        # @values = (
        #    { id => x, key => keythatwascompletedon },...
        # )
        $self->do_render({
            records             => \@values,
            queryRecordCount    => scalar(@values),
            totalRecordCount    => scalar(@values),
        });
    }
    catch {
        $log->error("In API autocomplete, Error: $_");
        $log->error(longmess);
        $self->render_error(400, { error_msg => $_ } );
    };
}

sub whoami {
    my $self    = shift;
    my $user    = $self->session('user'); # username from session cookie
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my $userobj = $mongo->collection('User')->find_one({username => $user});

    if ( defined ( $userobj )  ) {
        $userobj->update_set(lastvisit => $env->now);
        my $user_href   = $userobj->as_hash;
        my $group_aref  = $self->get_groups;
        $log->debug("groups aref: ",{filter=>\&Dumper,value=>$group_aref});
        if ( $env->is_admin($user_href->{username}, $group_aref)){
            $user_href->{is_admin} = 1;
        }
        # TODO:  move this to config file?
        # placed here initially for convenience but not very logical
        # since it has nothing to do with the user
        # and is used to populate the sensitivity cell on the header.
        $user_href->{sensitivity} = "OUO";
        $self->do_render({
            user    => $user,
            data    => $user_href,
        });
    }
    else {  
        # TODO:  put code here that creates the users database entry
        if ( $user ) {
            $self->do_render({
                user    => $user,
                data    => {},
            });
        }
        else {
            $self->render_error(404, {
                user    => "not valid",
                data    => { error_msg => "$user not found" },
            });
        }
    }
}

sub get_cidr_matches {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    try {
        my $req_href= $self->get_request_params;
        my $cidr    = $req_href->{request}->{params}->{cidr};
        my ($cidrbase,$cidrbits) = split(/\//,$cidr);
        my $ipobj   = Net::IP->new($cidr);
        my $mask    = substr($ipobj->binip, 0, $cidrbits);
        
        my @records = $mongo->collection('Entity')->get_cidr_ipaddrs($mask);    
        my $count   = scalar(@records);
        my $return_href = {
            records             => \@records,
            queryRecordCount    => scalar(@records),
            totalRecordCount    => $count,
        };
        $self->do_render($return_href);

    }
    catch {
        $log->error("in API cidr, Error: $_");
        $self->render_error(400, { error_msg => $_ } );
    };
}

sub get_form {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $form    = $env->forms;

    $log->debug("Forms is ",{filter=>\&Dumper, value=>$form});

    $self->do_render($form);
}

sub undelete {
    my $self    = shift;
    my $obj     = shift;
    my $req     = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $user    = $self->session('user');

    $log->debug("processing undelete");

    my $collection  = (split(/::/,$obj->type))[-1];
    my $href    = $obj->data;
    $log->debug("obj dump ",{filter=>\&Dumper, value=>$href});
    my %request = (
        collection  => lc($collection),
        id          => $href->{id},
        user        => $href->{owner},
        request     => $href,
    );
    my $col     = $mongo->collection($collection);
    my $restored    = ($col->api_restore(\%request))[0];
    $log->debug("restored obj ".ref($restored));
    $log->debug("restore id = ".$restored->id);
    push my @returnjson, $self->post_create_process($restored);

    $log->debug("Returnjson is ", {filter=>\&Dumper, value=>\@returnjson});

    my $data = {
        who => $req->{user},
        type=> $restored->get_collection_name,
        id  => $restored->id,
    };
    if ( ref($restored) eq "Scot::Model::Entry" ) {
        $data->{target} = $restored->target;
    }
    $self->env->mq->send("/topic/scot",{
        action  => "created",
        data    => $data,
    });
    if ( scalar(@returnjson) > 1 ) {
        $self->do_render(\@returnjson);
    }
    else {
        $self->do_render(pop @returnjson);
    }
}

=item B<export>

Create an exportable report
/scot/api/v2/export/:thing/:id

=cut

sub export {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $user    = $self->session('user');

    $log->debug("Export");

    try {
        my $collection  = $self->stash('thing');
        my $id          = $self->stash('id') + 0;
        my $object      = $mongo->collection(ucfirst($collection))->find_iid($id);
        my $href        = $self->create_export($collection, $object);

        $self->stash(foo => $href);
        $self->render();
        return;
        my $html    = $self->render_to_string();

        $log->debug("HTML is ",{filter=>\&Dumper, value=>$html});

        # $self->mail_to_user($user, $html, $collection, $id);
        # $self->do_render({ status => "Email generated and sent to user" } );


    }
    catch {
        $log->error("ERROR exporting: $_");
        $self->render_error(400, {
            data    => { error_msg => "export error: $_" },
        });
        
    };
}

sub mail_to_user {
    my $self    = shift;
    my $user    = shift;
    my $html    = shift;
    my $col     = shift;
    my $id      = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;

    my $addr    = $user . $env->export_email_addr_suffix;
    my $subject = "SCOT Export of $col - $id";
    my $msg = Mail::Send->new(Subject => $subject, To => $addr);
    $msg->set('Content-Type',"text/html");
    my $fh  = $msg->open;
    print $fh $html;
    $fh->close;
}

sub create_export {
    my $self    = shift;
    my $col     = shift;
    my $object  = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my $href    = $object->as_hash;
    $href->{export_type} = ucfirst($col);
    $href->{entities}    = $self->build_entity_export($object->id, $col);
    $href->{created}     = $self->stringify_epoch($href->{created});
    $href->{updated}     = $self->stringify_epoch($href->{updated});

    if ( $object->meta->does_role("Scot::Role::Entriable") ) {
        $href->{entries}     = $self->build_entry_export($object->id, $col);
    }

    if ( $object->meta->does_role("Scot::Role::Tags") ) {
        $href->{tags}   = $self->build_tag_export($object->id, $col);
    }

    $log->debug("export data is ",{filter=>\&Dumper,value=>$href});

    return $href;
}

sub stringify_epoch {
    my $self    = shift;
    my $epoch   = shift;
    my $dt      = DateTime->from_epoch(epoch => $epoch);
    return $dt->ymd." ".$dt->hms;
}

sub build_tag_export {
    my $self    = shift;
    my $id      = shift;
    my $col     = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my @appearances = map { $_->{apid} } 
        $mongo->collection('Appearance')->find({
            type            => 'tag',
            'target.type'   => $col,
            'target.id'     => $id,
        })->all;
    my @tags = map { $_->{value} } $mongo->collection('Tag')
                     ->find({ id => {'$in' => \@appearances}})->all;
    return wantarray ? @tags : \@tags;
}


sub build_entity_export {
    my $self    = shift;
    my $id      = shift;
    my $col     = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my @results = ();

    my $cursor  = $mongo->collection('Link')
                  ->get_linked_objects_cursor({
                        id  => $id, type => $col 
                    }, "entity");

    while ( my $entity = $cursor->next ) {
        my $record  = {
            value       => $entity->value,
            type        => $entity->type,
            location    => $entity->location,
        };
        my $entrycur    = $mongo->collection('Entry')
                          ->get_entries_by_target({
                            id => $entity->id, type => "entity"
                          });

        while ( my $entry = $entrycur->next ) {
            push @{$record->{entry}}, $entry->body_plain;
        }
        push @results, $record;
    }
    return wantarray ? @results : \@results;
}

sub build_entry_export {
    my $self    = shift;
    my $id      = shift;
    my $col     = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $mygroups    = $self->get_groups;
    my $user        = $self->session('user');
    my @summaries   = ();
    my $cursor = $mongo->collection('Entry')->get_entries_by_target({
                    id      => $id,
                    type    => $col
                    });

    $cursor->sort({id => 1});
    
    return $self->thread_entries($cursor);

}


1;
