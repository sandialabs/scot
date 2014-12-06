package Scot::Controller::Handler;

use lib '../../../lib';
use v5.10;
use strict;
use warnings;

use Data::Dumper;
use JSON;
use Time::HiRes qw(gettimeofday tv_interval);
use Scalar::Util qw(looks_like_number);
use MIME::Base64;

use Scot::Model::Alert;
use Scot::Model::Alertgroup;
use Scot::Model::Audit;
use Scot::Model::Event;
use Scot::Model::Incident;
use Scot::Model::Intel;
use Scot::Model::Entry;
use Scot::Model::Checklist;
use Scot::Model::Guide;
use Scot::Model::Parser;
use Scot::Model::Entity;
use Scot::Model::File;
use Scot::Model::Plugin;
use Scot::Model::Plugininstance;
use Scot::Model::Intel;
use base 'Mojolicious::Controller';

=head1 Scot::Controller::Handler

After a web request, passes through the Scot.pm router, most 
of them wind up here.  I'm not the only controller, but I am
the biggest and best. 

I am of type Mojolicious::Controller so I have lots of linkage 
back to Scot.pm

=head2 Methods

=over 4

=item B<parse_params>

commonly the following params are given to us:
 grid, columns, and filter

this function puts them in a handy dandy href for us

=cut

sub parse_params {
    my $self    = shift;
    my $href    = {};
    my $env     = $self->env;
    my $log     = $env->log;
    $href->{grid}       = $self->parse_json_param("grid");
    $href->{columns}    = $self->parse_json_param("columns");
    $href->{filter}     = $self->parse_json_param("filter");
    local $Data::Dumper::Indent = 0;
    $log->debug("Get Params: ", { filter => \&Dumper, value =>$href });
    return $href;
}

=item B<get>

 retrieve a set of things
 used mostly to display a "grid" of configurable columns

=over 4

=item B<Web API> C<GET /scot/:thing>

 params: grid        -> json obj, 
         columns     -> json array,
         filter      -> json obj,
         sort        -> json obj,

 returned json:  {   
            grid    : {
                start       :   int,
                sort_ref    :   { fieldname: -1|1, ... },
                limit       :   int,
            }, 
            filter  : {
                fieldname : /matchstring/, ...
            }, 
            columns : [ column1, column2, ... ],
        }

 the matchobj is optional, and only works with entity requests

=back

=cut

sub get {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $thing       = $self->stash('thing');
    my $collection  = $env->map_thing_to_collection($thing);
    my $timer       = $env->get_timer("GET /scot/$thing");

    my $settings_href   = $self->parse_params();
    my $columns_aref    = $settings_href->{columns};

    local $Data::Dumper::Indent = 0;

    $log->debug("GET /scot/$thing with ",
                { filter => \&Dumper, value=>$settings_href});

    my $idfield = $thing . "_id";

    my $viewfilter;
    if ( $settings_href->{filter}->{view_count} ) {
        $viewfilter = shift @{$settings_href->{filter}->{view_count}};
        $settings_href->{filter}->{view_count} = $viewfilter;

        $log->debug("View filter is now ", 
                    { filter => \&Dumper, value => $settings_href });
    }

    my $search_href   = {
        collection  => $collection,
        match_ref   => $self->build_match_ref($settings_href->{filter}),
        start       => $settings_href->{grid}->{start} // 0,
        sort_ref    => $settings_href->{grid}->{sort_ref} // { $idfield => -1},
    };
    
    $log->debug("Looking for ", 
                { filter => \&Dumper, value => $search_href});

    my $return_href = {
        title   => "$collection list",
        action  => "get",
        thing   => $thing,
        status  => "ok",
        data    => [],
        total_records   => 0,
    };

    my $cursor      = $mongo->read_documents($search_href);
    my $total       = $cursor->count;
    if ( $total == 0 ) {
        $self->render( json => $return_href );
        return;
    }
    my $limit       = $settings_href->{grid}->{limit} // 25;
    $log->debug("Limit is ".$limit);
    my $data_aref   = $self->build_grid_array($cursor, $limit, $columns_aref);
    my @returned_cols   = keys %{ $data_aref->[0] };


    # views sort filter handling because that field is synthesized at get time
    if ( $search_href->{sort_ref}->{'view'} ) {
        my $direction = $search_href->{sort_ref}->{view_count};
        my @sorted;
        if ( $direction == -1 ) {
            @sorted = sort { $b->{view_count} <=> $a->{view_count} } @$data_aref;
        }
        else {
            @sorted = sort { $a->{view_count} <=> $b->{view_count} } @$data_aref;
        }
        $data_aref = \@sorted;
    }

    # this should not be needed now
    # that view_count is an actual field
    # if ( $viewfilter ) {
    #    my @filtered = grep { $_->{view_count} == $viewfilter } @$data_aref;
    #    $data_aref = \@filtered;
    # }

    my $servertime  = &$timer;
    if (scalar( @{ $data_aref } ) > 0 ) {
        $return_href->{data}            = $data_aref;
        $return_href->{columns}         = \@returned_cols;
        $return_href->{total_records}   = $total;
        $return_href->{stimer}          = $servertime;
        $self->render(json => $return_href);
    }
    else {
        $return_href->{status}  = "no matching records",
        $self->render(json => $return_href);
    }
    $env->update_activity_log({
        type    => "view",
        who     => $self->session('user'),
        what    => "viewed $collection grid list",
        when    => $env->now,
        status  => $return_href->{status},
        data    => {
            match_ref   => $search_href,
        },
    });
    $env->activemq->send("activity",{
        action  => "view",
        type    => $collection,
    });
}

sub build_match_ref {
    my $self        = shift;
    my $filter_href = shift;
    my $env         = $self->env;
    my $log         = $env->log;
    my $match       = {};

    local $Data::Dumper::Indent = 0;

    $log->debug("building match_ref from ",
                { filter => \&Dumper, value =>$filter_href});

    my @datefields  = qw(updated created occurred discovered reported);
    my @numfields   = qw(view_count);

    while ( my ($k, $v) = each %{$filter_href} ) {
        if ( $k =~ /id/ ) {
            if ( ref($v) eq "ARRAY" ) {
                @$v = map { $_ + 0 } @$v;
            }
            else {
                $v = $v +0;
            }
        }

        if ( $k eq "tags" ) {
            $match->{$k} = { '$all' => $v };
        }
        elsif ( grep { /$k/ } @datefields ) {
            $log->trace("Datafield $k detected");
            my $epoch_href  = $v;
            my $begin       = $epoch_href->{begin};
            my $end         = $epoch_href->{end};
            $match->{$k}    = {
                '$gte'  => $begin,
                '$lte'  => $end,
            };
            $log->debug("match is now ", { filter => \&Dumper, value=> $match->{$k} });
        }
        elsif ( ref($v) eq "ARRAY" ) {
            $match->{$k}    = { '$in' => $v };
        }
        elsif ( grep { /$k/ } @numfields ) {
            $match->{$k}  = ($v + 0);
        }
        else {
            $match->{$k}    = qr/$v/i;
        }
    }
    $log->debug("match_ref is ", { filter => \&Dumper, value => $match});

    return $match;
}

=item B<read_ok(I<$object_ref>)>

check if the object can be viewed by a somebody

=cut

sub read_ok {
    my $self    = shift;
    my $obj     = shift;
    my $env     = $self->env;

    my $idfield     = $obj->idfield;
    my $collection  = $obj->collection;
    my $id          = $obj->$idfield;
    unless ( $obj->is_readable( $self->session('groups') ) ) {
        $env->update_activity_log({
            type    => "view",
            who     => $self->session('user'),
            what    => "Attempted View of $collection $id",
            when    => $env->now,
            status  => "fail",
            data    => {
                reason  => "insufficient permissions",
            }
        });
        $self->render(
            json    => {
                title   => "View One $collection $id",
                status  => "fail",
                action  => "get_one",
                thing   => $collection,
                id      => $id,
                data    => {
                    reason  => "insufficient permissions",
                }
            }
        );
        return undef;
    }
    return 1;
}


=item B<get_one>

get_one returns the data record for one object based on the integer
id number for that object.

=over 4

=item B<Web API> C<GET /scot/:thing/:id>

    You may pass JSON of the form to control the fields returned
    {
        columns: [ 'field1',... ],       # explicit want these fields
        filtered: [ 'fieldx',...],      # explicit filter these fields
    }
    default is to send all attributes that are gridviewable

    returns: json
    {
        title   => "View One $thing $id",
        status  => "ok",
        action  => "get_one",
        thing   => $thing,
        id      => $id,
        data    => {
            entity_id   => $entity->entity_id + 0,
            entity_type => $entity->entity_type,
            notes       => $entity->notes,
            geo_data    => $entity->geo_data,
            block_data  => $entity->block_data,
            reputation  => $entity->reputation,
            alerts      => scalar( @{ $entity->alerts } ),
            events      => scalar( @{ $entity->events } ),
            incidents   => scalar( @{ $entity->incidents } ),
        },
        stimer  => $seconds,
    }

=back

=cut

sub get_one {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $thing   = $self->stash('thing');
    my $id      = $self->stash('id') + 0;
    my $tz      = $self->session('tz') // 'UTC';
    my $timer   = $env->get_timer("get_one /$thing/$id");

    my $settings_href       = $self->parse_params();
    my $requested_fields    = $settings_href->{columns} // [];
    my $filtered_fields     = $settings_href->{filtered} // [];
    
    my $collection  = $env->map_thing_to_collection($thing);
    my $idfield     = $thing . "_id";
    my $match_ref   = { $idfield => $id };
    my $search_href = {
        collection  => $collection,
        match_ref   => $match_ref,
    };

    my $object      = $mongo->read_one_document($search_href);
    my $data_href;

    if ( defined $object ) {
        $object->log($log);
        $object->env($env);

        if ( $object->meta->does_role("Scot::Roles::Permittable") ) {
            unless ($self->read_ok($object))  {
                $self->render(
                    json    => {
                        title   => "View One $thing $id",
                        status  => "failed",
                        action  => "get_one",
                        thing   => $thing,
                        id      => $id,
                        data    => { reason => "not permitted" },
                        stimer  => &$timer,
                    }
                );
                return;
            }
        }

        $data_href  = $object->as_hash($requested_fields);

        if ( $object->meta->does_role("Scot::Roles::ViewTrackable") ) {
            $object->add_view_record(
                $env,
                $self->session('user'),
                $self->tx->remote_address,
            );
        }

        if ( $object->meta->does_role("Scot::Roles::Entitiable") ) {
            # in next version let's change this to entity_data 
            # instead of flairdata
            $log->debug("Requested an Entitiable object");
            $data_href->{flairdata} = $object->get_entity_data;
        }

        if ( $object->meta->does_role("Scot::Roles::Entriable") ) {
            $data_href->{entries}   = 
                $object->get_entries($self->session('groups'));
            $data_href->{entrycount} = $object->entry_count($mongo);
        }


        if ( ref($object) eq "Scot::Model::Event" ) {

        }
        if ( ref($object) eq "Scot::Model::Alert" ) {

        }
        if ( ref($object) eq "Scot::Model::Alertgroup" ) {
            my ( $alerts_aref, $displaycols_aref) = 
                $object->get_my_alerts($env);
            $data_href->{alerts}        = $alerts_aref;
            $data_href->{header}        = $displaycols_aref;
        }

#        this is only needed if synthesized attributes are excluded
#        not sure that would happen so removing until we need
#        if ( scalar( @{ $requested_fields } ) ) {
#            foreach my $field ( keys %{ $data_href } ) {
#                unless ( grep { /$field/ } @{$requested_fields} ) {
#                    delete $data_href->{$field};
#                }
#            }
#        }
#        foreach my $field ( @{ $filtered_fields } ) {
#            delete $data_href->{$field};
#        }

        $env->update_activity_log({
            type    => "view",
            who     => $self->session('user'),
            what    => "Viewed $thing $id",
            when    => $env->now,
            status  => "ok",
        });

        $self->render(
            json    => {
                title   => "View One $thing $id",
                status  => "ok",
                action  => "get_one",
                thing   => $thing,
                id      => $id,
                data    => $data_href,
                stimer  => &$timer,
            }
        );
    }
    else {
        $log->error("No matching object $thing $id");
        $env->update_activity_log({
            type    => "view",
            who     => $self->session('user'),
            what    => "Attempted View of $thing $id",
            when    => $env->now,
            status  => "fail",
            data    => {
                reason  => "no matching records",
            }
        });
        $self->render(
            json    => {
                title   => "View One $thing $id",
                status  => "fail",
                action  => "get_one",
                thing   => $thing,
                id      => $id,
                data    => {
                    reason  => "no matching records",
                },
                stimer  => &$timer,
            }
        );
    }
}

=item B<build_grid_array>

internal use

=cut 

sub build_grid_array {
    my $self            = shift;
    my $cursor          = shift;
    my $limit           = shift;
    my $columns_aref    = shift;

    $limit = $limit + 0;

    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my @data    = ();
    my $count   = 0;

    $log->debug("Building data array for grid");
    $log->debug("limit = $limit");
    $log->debug("cursor has ".$cursor->count." objects");
    if (defined $columns_aref) {
        $log->debug("want columns: ".join(',',@$columns_aref));
    }

        CURSOR_GETOBJ:
        while ( my $object  = $cursor->next ) {
            if ( $count < $limit  ) {
                my $href = $self->build_href_from_object($object, $columns_aref);
                if ( defined $href ) {
                    push @data, $href;
                    $count++;
                }
                $log->debug("processed $count objects");
            }
            else {
                $log->debug("reached limit");
                last CURSOR_GETOBJ;
            }
        }
    return \@data;
}

=item B<build_href_from_object>

internal use

=cut 

sub build_href_from_object {
    my $self        = shift;
    my $object      = shift;
    my $cols_aref   = shift;
    my $env         = $self->env;
    my $log         = $env->log;
    my $mongo       = $env->mongo;

    $object->log($log);
    $object->env($env);

    my $tz      = $self->session('tz');
    if ( defined $tz ) {
        $object->timezone($tz);
    }

    my $href    = $object->grid_view_hash($cols_aref);

    if ( $object->meta->does_role("Scot::Roles::Taggable") ) {
        if ( grep { /tags/ } @$cols_aref ) {
            unless ( defined $href->{tags} ) {
                $href->{tags} = $object->tags;
            }
        }
    }

    if ( ref($object) eq "Scot::Model::Alertgroup" ) {
        $href->{alertcount} = scalar( @{$object->alert_ids} );
    }

    if ( ref($object) eq "Scot::Model::Event" ) {
        $href->{entrycount} = $object->entry_count($mongo);
    }

    return $href;
}

=item B<parse_submitted_json>

most requests have a json component that is passed to the server
this pulls it out and returns it as a href

=cut

sub parse_submitted_json {
    my $self    = shift;
    my $req     = $self->req;
    my $json    = $req->json;
    my $env     = $self->env;
    my $log     = $env->log;
    local $Data::Dumper::Indent = 0;
    $log->debug("JSON from client: ",
                { filter => \&Dumper, value => $json});
    return $json;
}

=item B<create> 

creating an object from web input
The objects do most of the heavy lifting

=over 4

=item B<Web API> C<POST /scot/:thing>

    params:
        none    
    input:
    { json object with params listed in thing model }
    ---
    returns:
    {
        action  : "post",
        thing   : $thing,
        id      : new object id
        status  : $status
        reason  : string,
        stime   : int
    }
    notifications:
    {
        action  : "creation"
        type    : $thing
        id      : object id
        target_type : string,   # if entry
        target_id   : int,   # if entry
        is_task     : boolean,   # if entry
    }

=back

=cut

sub create  {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $thing   = $self->stash('thing');
    my $timer   = $env->get_timer("POST /$thing");
    my $groups  = $self->session('groups');
    
    $log->debug("Creating $thing from web input");
    $log->debug("session groups are ". join(', ',@$groups));

    if ( $thing eq "alertgroup" ) {
        $self->create_alertgroup();
        return;
    }

    if ( $thing =~ /user/i ) {
        $log->error("Attempt to create user");
        $self->render(
            text    => "Only Admin can create Users",
            status  => 403,
        );
        return;
    }

    my $class   = "Scot::Model::" . ucfirst($thing);
    my $object  = $class->new($self);

    $object->reset_oid; # prevent mongo oid conflicts
    $object->log($log); # pass in the logger for logging
    $object->env($env);

    $log->debug("object created");

    if ( $object->meta->does_role("Scot::Roles::Historable") ) {
        $log->debug("adding historical record");
        $object->add_historical_record({
            who     => $self->session('user'),
            what    => "created $thing",
            when    => $env->now,
        });
    }

    my $status  = "ok";
    my $reason;

    if ( $object->meta->does_role("Scot::Roles::Permittable") ) {
        $object->set_default_groups($groups);
    }

    if ( $object->meta->does_role("Scot::Roles::Ownable") ) {
        my $user    = $self->session('user');
        $object->owner($user);
    }

    my $object_id   = $mongo->create_document($object);
    my $idfield     = $object->idfield;
    $object->$idfield($object_id);

    if ( defined $object_id ) {

        $log->debug("Created Record for $thing");
        
        if ( $object->meta->does_role("Scot::Roles::Entitiable") ) {
            # alerts or entries
            if ( ref($object) eq "Scot::Model::Entry" ) {
                # this has been moved to Entry Model. remove after testing
                # $object->update_data_derrived_from_body;
            }
            if ( ref($object) eq "Scot::Model::Alert" ) {
                $object->extract_entities;
            }
            # alert group might need something
            # events incidents should not 
        }

        if ( ref($object) eq "Scot::Model::Alert" ) {
            $object->update_alertgroup($mongo);
        }

        if ( ref($object) eq "Scot::Model::Entry" ) {
            $object->update_target($mongo);
        }
 
        if ( ref($object) eq "Scot::Model::Plugininstance" ) {
           my $parent_id = $object->parent;
           my $target_id  = $object->target_id;
           my $target_type = $object->target_type;
           my $entry_obj   = Scot::Model::Entry->new({
              body        => 'Launching Plugin...',
              target_id   => $target_id,
              target_type => $target_type,
              parent      => $parent_id,
              log         => $log,
              owner   => $self->session('user'),
              env     => $env,
          });
          my $entry_id = $mongo->create_document($entry_obj);
          $log->debug('entry just created was ' . $entry_id);

          $object->entry_id($entry_id);
          $mongo->update_document($object);

          $env->activemq->send("activity",{
             action          => "creation",
             type            => "entry",
             id              => $entry_id,
             target_type     => $target_type,
             target_id       => $target_id,
           });

        }
    }
    else {
        $log->error("Failed to Write $thing to MongoDB");
        $status = "fail";
        $reason = "Mongo Error creating document";
    }
    my $servertime  = &$timer;;

    $self->render(
        json    => {
            action  => 'post',
            thing   => $thing,
            id      => $object_id,
            status  => $status,
            reason  => $reason,
            stime   => $servertime,
        }
    );

    $env->update_activity_log({
        type    => "create",
        who     => $self->session('user'),
        what    => "created $thing $object_id",
        when    => $env->now,
        data    => {
            status  => $status,
            reason  => $reason,
            origional_object  => $object->as_hash,
        },
    });

    my $aq_href     = {
        action  => "creation",
        type    => $thing,
        id      => $object_id,
    };
    if ($thing eq "entry") {
        $aq_href->{target_type} = $object->target_type;
        $aq_href->{target_id}   = $object->target_id;
        $aq_href->{is_task}     = $object->is_task;
    }
    # future refactor to $env->activemq->send($aq_href)
    $env->activemq->send("activity",$aq_href);

}

sub create_alertgroup {
    my $self    = shift;
    my $mongo   = $self->env->mongo;
    my $redis   = $self->env->redis;
    my $log     = $self->env->log;
    my $req     = $self->req;
    my $json    = $req->json;

    $log->debug("Creating Alertgroup from ".Dumper($json));

    my $data    = $json->{data};
    my $subject = $json->{subject};

    $log->debug("Subject is $subject");

    my $activemq= $self->env->activemq;
    my $timer   = $self->env->get_timer("POST /alertgroup");

    my $alertgroup_id   = $mongo->get_next_id("alertgroups");

    my @alert_ids;
    my $alertgroup_href;

    foreach my $alert_data_href ( @$data ) {
        my $alert_id;
        my $creation_time;

        if ( $json->{created} ) {
            $creation_time = $json->{created} + 0;
        }
        else {
            $creation_time = $self->env->now();
        }

        my $column_aref = $json->{columns} // [ keys %$alert_data_href ];

        my $alert_href  = {
            alertgroup  => $alertgroup_id,
            created     => $creation_time,
            sources     => $json->{sources} // [],
            status      => 'open',
            subject     => $subject,
            data        => $alert_data_href,
            columns     => $column_aref,
            guide_id    => $self->get_guide_id($subject),
            log         => $self->env->log,
            env         => $self->env,
        };
        my $alert_obj   = Scot::Model::Alert->new($alert_href);
        $alert_obj->searchtext($alert_obj->build_search_text());
        $alert_obj->add_historical_record({
            who     => $self->session('user'),
            what    => "created alert via web api",
            when    => $self->env->now(),
        });
        $alert_id    = $mongo->create_document($alert_obj);

        unless ( $alert_id ) {
            $log->error("FAILED to CREATE alert");
        }
        
        $alert_obj->alert_id($alert_id);
        $alert_obj->flair_the_data();

        $log->debug("Subject is $subject");

        $alertgroup_href    = {
            alertgroup_id   => $alertgroup_id,
            created         => $creation_time,
            guide_id        => $alert_obj->guide_id,
            message_id      => $alert_obj->message_id,
            when            => $alert_obj->when,
            updated         => $alert_obj->updated,
            status          => $alert_obj->status,
            subject         => $subject,
            sources         => $alert_obj->sources,
            events          => [],
            viewcount       => 0,
            'log'           => $log,
            env             => $self->env,
        };

        push @alert_ids, $alert_id;
        my $searchtext  = $alert_obj->searchtext;
        my $id          = $alert_obj->alert_id;

        $redis->add_text_to_search({
            text    => $searchtext,
            id      => $id,
            collection  => "alerts",
        });
    }
    $alertgroup_href->{alert_ids} = \@alert_ids;
    $log->debug("creating the alertgroup");
    my $alertgroup_obj  = Scot::Model::Alertgroup->new($alertgroup_href);
    my $agid            = $mongo->create_document($alertgroup_obj, -1);
    $activemq->send("activity", {
        type    => "alertgroup",
        action  => "creation",
        id      => $alertgroup_href->{alertgroup_id},
        alerts  => \@alert_ids,
    });
    my $servertime  = &$timer;;
    $self->render(
        json    => {
            action  => 'post',
            thing   => "alertgroup",
            id      => $alertgroup_id,
            status  => 'ok',
            stime   => $servertime,
        }
    );

}


sub get_guide_id {
    my $self    = shift;
    my $subject = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    $log->debug("Looking up Guide ID for $subject");

    $subject    =~ s/FW:[ ]*//;

    my $object  = $mongo->read_one_document({
        collection  => "guides",
        match_ref   => { guide => $subject },
    });

    if ( $object ) {
        return $object->guide_id;
    }

    $log->debug("No existing guide, creating...");

    my $guide   = Scot::Model::Guide->new({
        guide   => $subject,
    });

    $log->debug("attempting to save guide");

    if (defined $guide) {
        my $guide_id    = $mongo->create_document($guide);
        return $guide_id;
    } 
    else {
        $log->error("didnt create guide!");
    }
}

=item C<delete>

handle delete a thing route

=cut

sub delete  {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $thing   = $self->stash('thing');
    my $id      = $self->stash('id') + 0;
    my $timer   = $env->get_timer("DEL /$thing/$id");

    $log->debug("Deleting $thing $id");

    if ( $thing =~ /users/i ) {
        $self->render(
            text    => "Only Admin can delete a user",
            status  => 403,
        );
        return;
    }

    if ( $thing eq "alertgroup" ) {
        return $self->delete_alertgroup();
    }

    my $idfield     = $thing . "_id";
    my $oidfield    = "_id";
    my $match_ref   = { $idfield => $id };
    my $collection  = $env->map_thing_to_collection($thing);

    my $object      = $mongo->read_one_document({
        collection  => $collection,
        match_ref   => $match_ref,
    });
    
    my $status  = "fail";
    my $reason  = "";

    if ( defined $object ) {
        $object->env($env);
        $object->log($log);

        my $ok_to_delete = "yes";
        if ( $object->meta->does_role("Scot::Roles::Permittable") ) {
            unless ( $object->is_modifiable($self->session('groups')) ) {
                $ok_to_delete = "no";
            }
        }

        if ( $ok_to_delete eq "yes" ) {

            if ( $object->meta->does_role("Scot::Roles::Historable") ) {
                $object->add_historical_record({
                    who     => $self->session('user'),
                    what    => "deleted $thing $id",
                    when    => $env->now,
                });
            }
            if ( ref($object) eq "Scot::Model::Entry" ) {
                ( $status, $reason ) = $object->move_children;
            }
            if ( $object->meta->does_role("Scot::Roles::Entitiable") ) {
                $object->remove_self_from_entities($mongo);
            }
            if ( $mongo->delete_document($object) ) {
                if (ref($object) eq "Scot::Model::Alert" or
                    ref($object) eq "Scot::Model::Event" or
                    ref($object) eq "Scot::Model::Incident" ) {
                    $object->remove_self_from_references($mongo);
                }
                $status = "ok";
            }
        }
        else {
            $log->error("User not permitted to delete");
            $status = "fail";
            $reason = "delete not permitted";
        }
    }
    else {
        $status = "fail";
        $reason = "no matching object";
    }

    my $servertime  = &$timer;

    $self->render(
        json    => {
            title   => "Delete $thing",
            action  => "delete",
            thing   => $thing,
            status  => $status,
            reason  => $reason,
            stime   => $servertime,
        }
    );
    $env->update_activity_log({
        type    => "delete",
        who     => $self->session('user'),
        what    => "Deleted $thing $id",
        when    => $env->now,
        data    => {
            status  => $status,
            reason  => $reason,
            origional_object  => $object->as_hash,
        }
    });
    my $aq_href     = {
        action  => "deletion",
        type    => $thing,
        id      => $id,
    };
    if ($thing eq "entry") {
        $aq_href->{target_type} = $object->target_type;
        $aq_href->{target_id}   = $object->target_id;
        $aq_href->{is_task}     = $object->is_task;
    }
    $env->activemq->send("activity",$aq_href);
}

=item C<update>

 this is how you update object using the web api

=cut

sub update  {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $thing   = $self->stash('thing');
    my $id      = $self->stash('id')+0;
    my $timer   = $env->get_timer("PUT /$thing/$id");

    $log->debug("Attempting to update $thing $id");

    if ( $thing =~ /user/i ) { 
        $self->render(
            text    => "only Admin can update user wholesale",
            status  => 403,
        );
        return;
    }

    my $collection  = $env->map_thing_to_collection($thing);
    my $idfield     = $thing . "_id";
    my $match_ref   = { $idfield    => $id };

    my $object      = $mongo->read_one_document({
        collection  => $collection,
        match_ref   => $match_ref,
    });

    my $amq_href;

    my $status  = "ok";
    my $reason  = "";
    my $origobj = $object->as_hash;

    if ( defined $object ) {
        $object->env($env);
        $object->log($log);
        $amq_href    = {
            action  => "update",
            type    => $thing,
            id      => $id,
        };

        my $ok_to_modify    = "yes";
        if ( $object->meta->does_role("Scot::Roles::Permittable") ) {
            unless ( $object->is_modifiable($self->session('groups')) ) {
                $ok_to_modify = "no";
            }
        }

        if ( $ok_to_modify eq "yes" ) {

            my $modify_href = $object->build_modification_cmd($self);
            my $obj_type    = ref($object);
            my $function    = "apply_update";
            if ( $obj_type eq "Scot::Model::Alertgroup" ) {
                $function   = "apply_alertgroup_update";
            }
            if ( $mongo->$function($modify_href) ) {

                # after mod reload.  
                $object = $mongo->read_one_document({
                    collection  => $collection,
                    match_ref   => $match_ref,
                });

                if ( $obj_type eq "Scot::Model::Entry" ) {
                    $amq_href->{is_task}        = $object->is_task;
                    my ($t, $i) = $object->update_target($mongo);
                    # this is being moved into the model
                    # left here as comment until testing proves fruitful
                    # $object->update_data_derrived_from_body;
                    # need to put some amq messages here
                    # to handle a move better
                    my $thref = $modify_href->{data_ref}->{'$set'};
                    if ( $modify_href->{data_ref}->{'$set'}->{target_id} ) {
                        my $new_target_type = $thref->{target_type};
                        my $new_target_id   = $thref->{target_id};
                        $log->debug("new_target_type = $new_target_type");
                        $log->debug("new_target_id   = $new_target_id  ");
                        $object->update_children($env,
                                                 $new_target_type,
                                                 $new_target_id);
                        $env->activemq->send("activity",{
                            action      => "deletion",
                            type        => "entry",
                            id          => $object->entry_id,
                            target_type => $t,
                            target_id   => $i,
                        });
                        $env->activemq->send("activity",{
                            action      => "creation",
                            type        => "entry",
                            id          => $object->entry_id,
                            target_type => $new_target_type,
                            target_id   => $new_target_id,
                        });
                    }
                }

                if ( $obj_type eq "Scot::Model::Alert" ) {
                    $object->update_alertgroup($mongo);
                    $object->extract_entities;
                }

                if ( $obj_type eq "Scot::Model::Alertgroup" ) {
                    $object->refresh_ag_data($env); # update status etc.
                    $mongo->update_document($object);
                    foreach my $updated_alert_id (@{$object->alert_ids}) {
                        $env->activemq->send("activity",{
                            action  => "update",
                            type    => "alert",
                            id      => $updated_alert_id,
                        });
                    }
                }
            }
            else {
                $status = "fail";
                $reason = "error applying update";
            }
        }
        else {
            $log->error("Update of $thing $id not permitted");
            $status    = "fail";
            $reason    = "not permitted";
        }
    }
    else {
        $status    = "fail";
        $reason    = "no match";
    }

    my $servertime  = &$timer;
    $self->render(
        json    => {
            title   => "Update $thing $id",
            action  => "update",
            thing   => $thing,
            status  => $status,
            reason  => $reason,
            stime   => $servertime,
        }
    );
    $env->update_activity_log({
        who     => $self->session('user'),
        what    => "updated $thing $id",
        when    => $env->now,
        data    => {
            original_object => $origobj,
            new_object      => $object->as_hash,
        },
    });
    $env->activemq->send("activity",$amq_href);
}

=item C<unauthorized>

When a user tries to access a page that they aren't authorized to

=cut

sub unauthorized {
   my $self   = shift;

   my $return_href = {
       title   => "unauthorized access attempted",
       status  => "unauthorized",
   };

   $self->render( json => $return_href );
}


=item C<whoami>

Ever wake up in the morning and just wonder, "who am i?"  Yeah?  
Well you better lay off the sauce buddy.  Unfortunately, the 
client ties one on too an forgets who they are.

=cut

sub whoami {
    my $self    = shift;
    my $user    = $self->session('user');
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my $userobj = $mongo->read_one_document({
        collection  => "users",
        match_ref   => { username => $user },
    });

    if (defined $userobj) {
        my $user_href   = $userobj->as_hash;
        $self->render(
            json    => {
                title   => "whoami",
                action  => "whoami",
                user    => $user,
                data    => $user_href,
            }
        );
    }
    else {
        $self->render(
            json    => {
                title   => "whoami",
                action  => "whoami",
                user    => $user,
                status  => "no matching user",
            }
        );
    }
}

=item C<getgroups>

this function will return the list of groups from the LDAP
server that have "scot" in their name

=cut

sub getgroups {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $ldap    = $env->ldap;

    #if method == local
   
    

    #elsif method = ldap
    
    $self->render(
        json    => {
            title       => "SCOT Group List",
            action      => 'get',
            thing       => 'scotgroups',
            status      => 'ok',
            data        => {
                groups  => $ldap->get_scot_groups,
            },
        }
    );
}

=item C<get_promotion_object(I<$target, $id>)>

find an exist promotion target to promote something to

=cut

sub get_promotion_object {
    my $self        = shift;
    my $target      = shift;
    my $id          = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;
    my $collection  = $target . "s";
    my $idfield     = $target . "_id";

    my $object  = $mongo->read_one_document({
        collection  => $collection,
        match_ref   => { $idfield => $id },
    });

    if ( defined $object ) { 
        $object->env($env);
        $object->log($log);
        return $object;
    }

    $log->error("Failed to find promotion target $target $id!");
    return undef;
}

sub get_new_promotion_object {
    my $self    = shift;
    my $target  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $class   = "Scot::Model::".ucfirst($target);
    my $object  = $class->new({
        owner           => $self->session('user'),
        readgroups      => [],
        modifygroups    => [],
        status          => 'open',
        subject         => "promoted $target",
        env             => $env,
        'log'           => $log,
    });
    return $object;
}

=item C<promote>

handle promotions

=cut

sub promote {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $json    = $self->get_json;
    my $timer   = $env->get_timer("Promote");

    my $thing_to_be_promoted    = $json->{thing};
    my $ids_to_be_promoted      = $json->{id};
    my $promotion_collection    = $thing_to_be_promoted . "s";
    my $promotion_idfield       = $thing_to_be_promoted . "_id";

    unless ( ref($ids_to_be_promoted) eq "ARRAY" ) {
        $ids_to_be_promoted     = [ $ids_to_be_promoted ];
    }

    # alerts -> events -> incidents
    my $promotion_target_type   = "event";
    if ( $thing_to_be_promoted eq "event" ) {
        $promotion_target_type  = "incident";
    }

    # if we have  a target_id, we are promoting to an existing thing
    my $promotion_target_id = $json->{target_id};
    my $promotion_object;

    my $amq_action;
    if ( defined $promotion_target_id ) {
        $promotion_object   = $self->get_promotion_object(
            $promotion_target_type, $promotion_target_id
        );
        $amq_action   = "update";
    }
    else {
        $log->debug("Creating new promotion target $promotion_target_type");

        $promotion_object   = 
            $self->get_new_promotion_object($promotion_target_type);

        my $promoted_idfield    = $promotion_object->idfield;
        my $poid = $mongo->create_document($promotion_object);
        $promotion_object->$promoted_idfield($poid);
        $amq_action   = "creation";
    }

    unless ($promotion_object) {
        $self->render(
            json    => { 
                title   => "Invalid promotion.",
                action  => "put",
                thing   => $promotion_target_type,
                data    => "Failed to find or create $promotion_target_type",
                status  => 'fail',
            }
        );
        return undef;
    }
    my $promotion_target_idfield    = $promotion_object->idfield;

    my @rows;
    my $header;
    my $readgroups_aref;
    my $modifygroups_aref;
    my $subject;
    my $sources;
    my $search_html;

    foreach my $promotee_id (@$ids_to_be_promoted) {
        my $promotee_obj    = $mongo->read_one_document({
            collection  => $promotion_collection,
            match_ref   => { $promotion_idfield => $promotee_id },
        });
        unless ( defined $promotee_obj ) {
            $log->debug("Failed to find object matching ".
                        "$promotion_collection $promotee_id");
            next;
        }
        $promotee_obj->env($env);
        $promotee_obj->log($log);
        $promotee_obj->status("promoted");

        if ( ref($promotee_obj) eq "Scot::Model::Alert" ) {
            # update the alertgroup status
            my $alertgroup_id   = $promotee_obj->alertgroup;
            $mongo->apply_update({
                collection  => "alertgroups",
                match_ref   => { alertgroup_id => $alertgroup_id },
                data_ref    => { '$set' => { status => "promoted" } },
            });
            $env->activemq->send("activity",{
                action  => "update",
                type    => "alertgroup",
                id      => $alertgroup_id,
            });
        }

        $readgroups_aref    = $promotee_obj->readgroups();
        $modifygroups_aref  = $promotee_obj->modifygroups();
        $subject            = $promotee_obj->subject();
        $sources            = $promotee_obj->sources();

        if ( ref($promotee_obj) eq "Scot::Model::Alert" ) {
            push @rows, $promotee_obj->make_data_row;
            $header = $promotee_obj->make_data_header;
            $search_html    = $promotee_obj->get_splunk_search;
            $promotee_obj->add_event($promotion_object->event_id);
        }
        else {
            push @rows, qq|<p>Promoted from Event |.
                        qq|<a href="/#/event/$promotee_id">|.
                        qq|$promotee_id</a></p>|;
            $promotee_obj->add_incident($promotion_object->incident_id);
        }
        $mongo->update_document($promotee_obj);
        $env->activemq->send("activity",{
            action  => "update",
            type    => $thing_to_be_promoted,
            id      => $promotee_id,
        });
    }

    # now update the promotion target

    my $entry_html;

    if ( $amq_action eq "creation" ) {
        $promotion_object->readgroups($readgroups_aref);
        $promotion_object->modifygroups($modifygroups_aref);
        $promotion_object->subject($subject);
        $promotion_object->sources($sources);
    }

    if ( ref($promotion_object) eq "Scot::Model::Event") {
        $promotion_object->add_alerts(@$ids_to_be_promoted);
        $entry_html =   $search_html .
                        qq|<table class="alertTableHorizontal">|. 
                        $header . join('',@rows).qq|</table>|;

    }
    else {
        $promotion_object->add_events(@$ids_to_be_promoted);
        $entry_html = join('',@rows);
    }

    $promotion_object->add_entry({
        owner   => $self->session('user'),
        when    => time(),
        body    => $entry_html,
    });

    $mongo->update_document($promotion_object);
    my $idfield = $promotion_object->idfield;
    $env->activemq->send("activity",{
        action  => $amq_action,
        type    => $promotion_target_type,
        id      => $promotion_object->$idfield,
    });

    $env->update_activity_log({
        type    => "promote",
        who     => $self->session('user'),
        what    => "promoted $thing_to_be_promoted to $promotion_target_type",
        when    => time(),
        data    => {
            initial     => $thing_to_be_promoted,
            initial_id  => $ids_to_be_promoted,
            final       => ref($promotion_object),
            final_id    => $promotion_object->$idfield,
        },
    });

    $self->render(
        json    => {
            title   => "Promote $thing_to_be_promoted to $promotion_target_type",
            action  => "put",
            thing   => $promotion_target_type,
            id      => $promotion_object->$idfield,
            status  => "ok",
            data    => {
                initial     => $thing_to_be_promoted,
                initial_id  => $ids_to_be_promoted,
                final       => ref($promotion_object),
                final_id    => $promotion_object->$idfield,
            },
            stimer  => $timer,
        }
    );
}
        

sub chat {

}

sub candy {

}

=item C<ihcalendar>

get the data to pump into the mojo template to display
the ih calendar

=over 4

=item B<GET /scot/ihcalendar>

params      values
------      ------
start       unix epoch (int)
end         unix epoch (int)

returns:    JSON
 [  
    {
        id      :   integer event_id,
        title   :   "username",
        allDay  :   js boolean, always true
        starg   :   string representation of date
    }, ...
 ]

=cut

=back

=cut

sub ihcalendar {
    my $self        = shift;
    my $env         = $self->env;
    my $log         = $env->log;
    my $collection  = "incident_handler";
    my $mongo       = $env->mongo;
    my $start       = $self->param("start") + 0;
    my $end         = $self->param("end") + 0;
    my $start_dt    = DateTime->from_epoch(epoch=>$start);
    my $end_dt      = DateTime->from_epoch(epoch=>$end);
    my $match_ref   = { 
        date    => {
            '$gte'  => $start_dt,
            '$lte'  => $end_dt,
        }
    };
    my $cursor  = $mongo->read_documents({
        collection  => "incident_handler",
        match_ref   => $match_ref,
    });

    my @events;

    while ( my $event = $cursor->next_raw ) {
        my ($d, $j) = split(/ /, $event->{date}, 3);
        my $e       = {
            id      => $event->{_id},
            title   => $event->{user},
            allDay  => Mojo::JSON->true,
            start   => $d,
        };
        push @events, $e;
    }
    $self->render( json => \@events );
}

=item C<current_handler>

who is on the hotseat today?

=over 4

=item B<GET /scot/current_handler>

 params:        values:
 ---
 returns:       JSON
 {
        incident_handler   :   "username"
 }, ...

=cut

=back

=cut

sub current_handler {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $dt      = DateTime->now();
    my $y       = $dt->year;
    my $m       = $dt->month;
    my $d       = $dt->day;

    my $todaydt = DateTime->new(
        year    => $y,
        month   => $m,
        day     => $d,
        hour    => 0,
        minute  => 0,
        second  => 0,
    );
    my $match_ref   = {
        date    => $todaydt
    };
    my $cursor  = $mongo->read_documents({
        collection  => "incident_handler",
        match_ref   => $match_ref,
    });
    my $href    = $cursor->next_raw;
    $self->render(
        json    => { incident_handler => $href->{user} },
    );
}

=item C<create_ihcal_entry>

create a incident handler entry

=cut

sub create_ihcal_entry {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $handler = $self->param('handler');
    my $start   = $self->param('start_date');
    my $end     = $self->param("end_date");

    my $start_dt    = $self->get_ih_datetime($start);
    my $end_dt      = $self->get_ih_datetime($end);
    my $current_dt  = $start_dt;

    $log->debug("creating ihcal entry");

    while (DateTime->compare($current_dt, $end_dt) <= 0 ) {
        my $data_href   = {
            user    => $handler,
            date    => $current_dt,
        };

        my $cursor = $mongo->read_documents({
            collection  => "incident_handler",
            match_ref   => { date => $current_dt },
        });
        my $ih_entry_href = $cursor->next_raw;
        if ( defined $ih_entry_href ) {
            if ( $mongo->apply_update({
                    collection  => "incident_handler",
                    match_ref   => { date => $current_dt },
                    data_ref    => $data_href,
                    opts_ref    => { safe => 1, upsert => 1},
                })) {
                $log->debug("created ih cal entry");
            }
            else {
                $log->error("failed to update ih cal entry for $handler");
            }
        }
        else {
            my $collection  = $mongo->db->get_collection("incident_handler");
            $collection->insert($data_href);
            if ( $mongo->mongo_had_error ) {
                $log->error("Error creating ih cal entry:",
                            { filter => \&Dumper, value => $data_href});
            }
        }
        $current_dt = $current_dt->add(days=>1);
    }
    $self->redirect_to("/ng/incident_handler.html");
}

sub get_ih_datetime {
    my $self    = shift;
    my $dstring = shift;

    my ($date, $junk, $month, $day, $year);

    ($date, $junk) = split(/ /,$dstring, 2);
    my $dt;
    if ($date =~ /\d+/) {
        ($month, $day, $year) = split(/\//, $date, 3);

        $dt = DateTime->new(
            year    => $year,
            month   => $month,
            day     => $day,
            hour    => 0,
            minute  => 0,
            second  => 0
        );
    } 
    else {
        my $strp = new DateTime::Format::Strptime(
            pattern => '%a %b %d %Y %T %Z',
            locale  => 'en_US',
        );
        $dt = $strp->parse_datetime($dstring);
    }
    return $dt;
}

=item C<get_entity_info> 

    this is a secondary call that happens when a user clicks on an Entity
    that is highlighted in the UI (flair).  This will provide detailed
    info for the pop up.
    query is driven by submitted json 
    {
        entity_value: "string" | [ "string1", "string2", ... ]
        entity_type: "string"
    }
    both of the values come from an array of hashes the server sent with
    the original request for the Entitiable object

=cut

sub get_entity_info {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $href    = $self->parse_json_param("match");
    my $limit   = $self->param("limit") // 100;
    my $redis   = $env->redis;
    
    my @entity_hrefs    = (); # what we are returning

    $log->debug("get_entity_info for ",
                { filter => \&Dumper, value => $href});

    my $entity_value_aref    = $href->{entity_value};
    unless ( ref($entity_value_aref) eq "ARRAY" ) {  
        # if it isn't an array, make it so
        $entity_value_aref = ($entity_value_aref);
    }
 
    foreach my $entity_value (@$entity_value_aref) {
        my $entity_href = $redis->get_redis_entity_data($entity_value, 1);
        $entity_href->{log} = $log;
        $entity_href->{env} = $env;
        unless ( $entity_href->{count} > 0 ) {
            $log->debug("unseen entity $entity_value");
        }
        my $entity_obj  = Scot::Model::Entity->new($entity_href);
        $entity_obj->get_extended_data;
        my $href = $entity_obj->as_hash;
        delete $href->{'alerts'};
        my $subject_href = $self->build_id_subject_structure($href, $limit);
        foreach my $type (qw(alertgroups events incidents intels)) {
            $href->{$type} = $subject_href->{$type};
        }
        push @entity_hrefs, $href;
    }

    if ( scalar(@entity_hrefs) > 0 ) {
        $self->render(
            json    => {
                title   => "SCOT Entity INFO",
                action  => "get",
                thing   => "entity",
                status  => "ok",
                data    => \@entity_hrefs,
            }
        );
    }
    else {
        $self->render(
            json    => {
                title   => "SCOT Entity",
                action  => 'get',
                thing   => 'entity',
                status  => 'fail',
                data    => 'no matching documents',
            }
        );
    }
}

sub build_id_subject_structure {
    my $self    = shift;
    my $href    = shift;
    my $limit   = shift;
    my $results = {};
    my $env     = $self->env;
    my $mongo   = $env->mongo;


    if($limit <= 0) {
       $limit = 99999999999;
    }
    foreach my $type (qw(events intels alertgroups incidents)) {
        my @ids = ();
        if(defined($href->{$type})) { #by far the slowest part of this is the subject lookup and manipulation so lets limit that by default
           for(my $i = 0; ($i < scalar(@{$href->{$type}})) && $i < $limit; $i++) {
              push @ids, ($href->{$type}[$i] + 0);
           }
        }
        if (scalar(@ids) > 0 ) {
            my $idfield = $mongo->get_id_field_from_collection($type);
            my $cursor  = $mongo->read_documents({
                collection  => $type,
                match_ref   => { $idfield => { '$in' => \@ids } },
            });
            while ( my $href = $cursor->next_raw ) {
                my $target_id   = $href->{$idfield};
                $results->{$type}->{$target_id} = { 
                    subject => $href->{subject} 
                };
            }
        }
    }
    return $results;
}

sub get_stub_href {
    my $self    = shift;
    my $ev      = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $entity  = Scot::Model::Entity->new({
        created     => $env->now,
        value       => $ev,
        entity_type => 'ipaddr',
    });
    $entity->env($env);
    $entity->log($log);
    $entity->update_data($mongo);
    $entity->expensive_update_data($mongo);
    return $entity->as_hash();
}

sub is_ipaddr {
    my $self        = shift;
    my $ev          = shift;
    my $IP_REGEX    = qr{
        \b                                              # word boundary
        (   # first 3 ip (with optional [.] (.) \{.\} )
            (?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\(*\[*\{*\.\)*\]*\}*){3} 
            # last octet
            (?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)            
        )
        \b                                              # word boundary
    }xms;
    if ( $ev =~ $IP_REGEX ) {
        return 1;
    }
    return undef;
}

sub put_entity_info {
    my $self    = shift;
    my $env     = $self->env;
    my $redis   = $env->redis;
    my $log     = $env->log;
    my $user    = $self->session('user');
    my $req     = $self->req;
    my $json    = $req->json;

    $log->debug("updating entity info with ",
                { filter => \&Dumper, value => $json});
    
    my $entity   = $json->{entity_value};
    $entity = lc $entity;
    my $note_text = $json->{note};
    $redis->set_entity_note($entity, $user, $note_text);
   
    $self->render(
        json    => {
            title   => "SCOT Entity Update",
            action  => 'put',
            thing   => 'entity',
            status  => 'ok',
        }
    );
    
    
    
}

=item C<get_entity_data_for_entry>

This route is used when a new entry is submitted and we need to 
get flair info for display

=cut

sub get_entity_data_for_entry {
    my $self        = shift;
    my $env         = $self->env;
    my $log         = $env->log;
    my $mongo       = $env->mongo;
    my $timer       = $env->get_timer("get_entity_data_for_entry");
    my $id          = $self->stash('id') + 0;
    my $idfield     = "entry_id";
    my $collection  = "entries";

    my $entry  = $mongo->read_one_document({
        collection  => $collection,
        match_ref   => { $idfield => $id },
    });
    # add this
    $entry->env($env);

    my $data    = $entry->get_entity_data();

    my $stimer  = &$timer;
    $self->render(
        json    => {
            title   => "Entity Data For entry $id",
            thing   => "entity_data",
            target  => "entry",
            id      => $id,
            status  => 'ok',
            stime   => $stimer,
            data    => $data,
        }
    );
}


sub get_tags_autocomplete {
    my $self        = shift;
    my $env         = $self->env;
    my $log         = $env->log;
    my $mongo       = $env->mongo;
    my $timer       = $env->get_timer("GET /scot/tags");

    my @tag_objs    = $mongo->read_documents({
        collection  => "tags",
        all         => 1,
    });
    my @data    = map { $_->text } @tag_objs;
    my $servertime = &$timer;
    if (scalar(@data) > 0 ) {
        $self->render( 
            json    => {
                title   => "Tag Autocomplete List",
                action  => 'get',
                thing   => 'tags',
                status  => 'ok',
                data    => \@data,
                stimer  => $servertime,
            }
        );
    }
}

# need to update to new

sub update_viewcount_old {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $type    = $self->stash('thing');
    my $id      = $self->stash('id') + 0;
    my $collection  = $mongo->plurify_name($type);
    my $idfield     = $type . "_id";

    my $job = $mongo->db->run_command({
        findAndModify   => $collection,
        query           => { $idfield => $id },
        update          => { '$inc' => { view_count => 1 } },
    });
    my $new_view_count  = $job->{value}->{view_count} + 1;

    if ( $mongo->mongo_had_error ) {
        $log->error("Mongo had Error incrementing $type view count");
    }
    $self->render(
        json    => {
            title   => "update view count",
            action  => "update_viewcount",
            target  => $type,
            id      => $id,
            view_count  => $new_view_count,
            status  => 'ok',
        }
    );
    $env->activemq->send("activity",{
        action      => "view",
        viewcount   => $new_view_count,
        type        => $type,
        id          => $id,
    });
}

sub refresh_alertgroup_status {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $timer   = $env->get_timer("refresh alertgroup status");

    my $alertgroup_id   = $self->stash('id') + 0;

    $log->debug("Refreshing Alertgroup $alertgroup_id status");

    my $alertgroup_object = $mongo->read_one_document({
        collection  => "alertgroups",
        match_ref   => { alertgroup_id  => $alertgroup_id },
    });

    my $data_href;
    my $refresh_status  = "ok";
    if ( $alertgroup_object ) {
        $alertgroup_object->refresh_ag_data($env);
        $data_href                  = $alertgroup_object->as_hash;
        $data_href->{views}         = $alertgroup_object->view_count;
        $data_href->{viewed_by}     = $alertgroup_object->viewed_by,
        $data_href->{alertcount}    = scalar(@{$alertgroup_object->alert_ids});
    }
    else {
        $data_href      = "no matching alertgroup";
        $refresh_status = "failed";
    }
    $self->render(
        json    => {
            title   => "Alertgroup Status Refresh",
            action  => "get",
            thing   => "alertgroup",
            id      => $alertgroup_id,
            data    => $data_href,
            stime   => &$timer,
        }
    );
}

sub update_viewcount {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $timer   = $env->get_timer("update_viewcount");
    my $thing   = $self->stash('thing');
    my $id      = $self->stash('id') + 0;
    my $idfield = $thing . "_id";
    my $user    = $self->session('user');
    my $now     = $env->now;
    my $ipaddr  = $self->tx->remote_address;

    my $object  = $mongo->read_one_document({
        collection  => $thing . "s",    # all ViewTrackables are easily plurable
        match_ref   => { $idfield => $id },
    });

    if ( $object ) {
        if ( $object->meta->does_role("Scot::Roles::ViewTrackable") ) {
            my $viewed_href = $object->viewed_by;
            my $view_count  = $object->view_count;
            $object->view_count($view_count+1);
            $viewed_href->{$user}->{count}++;
            $viewed_href->{$user}->{when} = $now;
            $viewed_href->{$user}->{from} = $ipaddr;
            $object->viewed_by($viewed_href);
            $mongo->update_document($object);

            $self->render(
                json    => {
                    title   => "update views",
                    target  => $thing,
                    id      => $id,
                    view_count  => $object->view_count,
                    status  => 'ok',
                }
            );
            $env->activemq->send("activity",{
                action  => "view",
                type    => $thing,
                id      => $id,
                viewcount   => $object->view_count,
            });
        }
        else {
            $log->error("Tried to update viewcount of something not ViewTrackable");
        }
    }
    else {
        $log->error("No matching object $thing $id");
    }
}

=back

=cut 

sub alertgroup_lookup {
    my $self        = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $alert_id    = $self->stash('id') + 0;

    my $alert_obj   = $mongo->read_one_document({
        collection  => "alerts",
        match_ref   => { alert_id => $alert_id } 
    });

    my $alertgroup_id;
    if ( $alert_obj ) {
        $alertgroup_id    = $alert_obj->alertgroup;
    }
    else {
        $alertgroup_id  = -1;
    }
    $self->render(
        json    => {
            title           => "Alertgroup Lookup",
            alertgroup_id   => $alertgroup_id,
            alert_id        => $alert_id,
        }
    );
}

sub get_plugins_list {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $type    = $self->stash('type');
    my $value   = $self->stash('value'); # future proofing

    $log->debug("Getting plugin list for $type : $value");

    my $cursor  = $mongo->read_documents({
         collection  => "plugins",
         match_ref   => { entity_types => $type },
     });
     my @plugins;
     while ( my $href = $cursor->next_raw ) {
         push @plugins, $href;
     }
     $self->render(
        json    => {
            title   => "Plugin List",
            data    => \@plugins,
        }
    );
}

=item C<sync>

This function is for the route /scot/sync/:collection/:since 
:collection = all | alerts | events | incidents | entries
:since = seconds since epoch, get things after this point

returns a json document of  form:
{
    alerts: [ { alert_obj }, ... ],
    events: [ { event_obj }, ... ],
    ...
}

=cut

sub sync {
    my $self            = shift;
    my $env             = $self->env;
    my $log             = $env->log;
    my $mongo           = $env->mongo;
    my $collection      = $self->stash('collection');
    my $since           = $self->stash('since') + 0;
    my $myreadgroups    = $self->session('groups');
    my @colls;
    my %data;   

    $log->debug(" ===== SYNC ===== \n".
                " "x56 . " Collection   = $collection\n".
                " "x56 . " Since        = $since\n".
                " "x56 . "=====");

    if ( $collection eq 'all' ) {
        push @colls, qw(alerts events incidents entries);
    }
    else {
        push @colls, $collection;
    }

    foreach my $col (@colls) {
        my $query_href  = {
            collection  => $col,
            match_ref   => { 
                'updated'       => { '$gt' => $since }, 
                'readgroups'    => { '$in' => $myreadgroups },
            },
            sort_ref    => { updated => 1 },
        };
        my $cursor      = $mongo->read_documents($query_href);
        my @results;
        while ( my $href    = $cursor->next_raw ) {
            push @results, $href;
        }
        $data{$col}     = \@results;
    }
    $self->render(
        json    => {
            title   => "SCOT Sync Refresh",
            status  => 'ok',
            action  => "get",
            data    => \%data,
        }
    );
}

sub get_updated {
    my $self            = shift;
    my $env             = $self->env;
    my $log             = $env->log;
    my $mongo           = $env->mongo;
    my $collection      = $self->stash('collection');
    my $since           = $self->stash('since') + 0;
    my $until           = $self->stash('until') + 0;
    my $myreadgroups    = $self->session('groups');
    my %data;   
    
    my @collections;
    if ( $collection eq "all" ) {
        push @collections, qw(alerts events incidents);
    }
    else {
        push @collections, $collection;
    }

    foreach my $col (@collections) {
        my $query_href  = {
            collection  => $col,
            match_ref   => {
                'updated'       => { '$gte'  => $since },
                'readgroups'    => { '$in'  => $myreadgroups },
            },
            sort_ref    => { updated => 1},
        };
        if ( $until > 0 and $until > $since ) {
            $query_href->{match_ref}->{'updated'}->{'$lte'} = $until;
        }
        my $cursor  = $mongo->read_documents($query_href);
        my @results;
        while ( my $obj = $cursor->next ) {
            my $idfield = $obj->idfield;
            my $id      = $obj->$idfield;
            push @results, $id;
        }
        $data{$col} = \@results;
    }
    $self->render(
        json    => {
            title   => "SCOT updated things",
            status  => 'ok',
            action  => 'get',
            data    => \%data,
        }
    );
}


1;

sub get_services {
   my $self    = shift;
   my $env     = $self->env;
   my $log     = $env->log;

   my %data;

   


   $self->render(
      json  => {
         title   => "SCOT services",
         status  => "ok",
         action  => "get",
         data    => \%data,
      }
   );
}

sub as_bool {
   my $self = shift;
   my $bool = shift;
   if($bool == 0) {
    return Mojo::JSON->false;
   } else {    
    return Mojo::JSON->true;
   }

}

sub get_auth_settings {
   my $self    = shift;
   my $env     = $self->env;
   my $log     = $env->log;
   my $mongo   = $env->mongo;

   my %data;
   my $query_href  = {
      collection  => 'users',
      match_ref   => {},
   };
   my $cursor  = $mongo->read_documents($query_href);
   my @results;
   my $groups = {};
   my $users = {};
   while ( my $obj = $cursor->next ) {
      my $username = $obj->{'username'};
      my $user_groups = ();
      if(defined($obj->{'groups'})) {
         $user_groups   = $obj->{'groups'};
      }
      foreach my $group (@{$user_groups}) {
         push @{$groups->{$group}}, $username;
      }
      $users->{$username} = {};
      $users->{$username}->{'groups'} = $user_groups;
      $users->{$username}->{'active'} = $self->as_bool($obj->active);
      $users->{$username}->{'local_acct'} = $self->as_bool($obj->local_acct);
      $users->{$username}->{'fullname'} = $obj->fullname;
      $users->{$username}->{'lockouts'} = $obj->lockouts;
   }
  
   $data{'groups'} = $groups;
   $data{'users'}  = $users;
   $data{'method'} = 'local';
   $self->render(
      json  => {
         title   => "SCOT services",
         status  => "ok",
         action  => "get",
         data    => \%data,
      }
   );
}

sub get_stats {
   my $self    = shift;
   my $env     = $self->env;
   my $log     = $env->log;
   my $mongo   = $env->mongo;

   my $data = {};
   
   $data->{'overview'} = `/usr/bin/landscape-sysinfo`;
   $data->{'overview'} =~ s/https:\/\/.*//g;
   $data->{'overview'} =~ s/Graph this .*//g;
   $data->{'overview'} .=  `/etc/update-motd.d/98-reboot-required`;
   $data->{'overview'} .=  `/etc/update-motd.d/91-release-upgrade`;   

   $data->{'overview'} = `/etc/update-motd.d/00-header` . $data->{'overview'};

   $self->render(
      json  => {
         title   => "SCOT services",
         status  => "ok",
         action  => "get",
         data    => $data,
      }
   );
}


sub confirm {
  my $self = shift;
  my $url  = $self->param('url');
  $url = decode_base64($url);
  $self->render( url => $url );
}

__END__

=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

=head1 SEE ALSO

=cut

=over 4

=item L<Scot>

=item L<Scot::Util::Mongo>

=back

