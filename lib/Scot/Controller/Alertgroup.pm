package Scot::Controller::Alertgroup;

use lib '../../../lib';
use v5.10;
use strict;
use warnings;

use Data::Dumper;
use Scot::Util::Mongo;
use JSON;
use Time::HiRes qw(gettimeofday tv_interval);

use Scot::Model::Alert;
use Scot::Model::Alertgroup;
use Scot::Model::Entity;
use Scot::Model::Entry;

use base 'Mojolicious::Controller';

=item C<get_alertgroup>
    This will get the data about the alerts comprising the alertgroup
=cut

sub get_alertgroup {
    my $self    = shift;
    my $log     = $self->app->log;
    my $mongo   = $self->mongo;
    my $timer   = $self->get_timer("get_alertgroup");

    my $columns_aref    = $self->parse_cols_requested();
    my $alertgroup_id   = $self->stash('id') + 0;
    my $grid_settings   = $self->parse_grid_settings();

    my $sort_ref    = $grid_settings->{sort_ref};
    my $limit       = $grid_settings->{limit};
    my $start       = $grid_settings->{start};

    # all alerts in an alertgroup have the alertgroup_id stored in their
    # alertgroup attribute.
    my $cursor  = $mongo->read_documents({
        collection  => "alerts",
        match_ref   => { alertgroup => $alertgroup_id },
        sort_ref    => $sort_ref,
        limit       => $limit,
        start       => $start,
    });

    # variables to hold accumulated values of alertgroup
    my $activitystatus;             # 
    my @displaycolumns;             # the data columns in alerts
    my @data;                       # the hrefs of data for each member alert

    my @entries;
    my @entities;
    while ( my $alert_object = $cursor->next ) {
        $alert_object->update_entity_collection($mongo); 
        my $href    = $alert_object->as_hash($columns_aref); 
        unless (defined $href->{entities} ) {
            # didn't ask for entity column  but give it anyway
            $href->{entities} = $alert_object->entities;
        }
        push @entities, @{$href->{entities}};

        if ( scalar(@displaycolumns) < 1 ) {
            # do this only once and assume that columns are uniform
            # across the member alerts. 
            @displaycolumns = keys %$href;
        }

        $alert_object->add_view_record($self);
        push @data, $href;

        my ( $entry_aref, $junk ) = $alert_object->get_entries($self);
        push @entries, @$entry_aref;
    }

    my $flair_href = $self->get_flair_data(\@entities);

    @entries    = sort { $a->{entry_id} <=> $b->{entry_id} } @entries;

    my $servertime  = &$timer;

    if ( scalar(@data) > 0 ) {
        $self->render(
            json    => {
                title   => "Alertgroup Member List",
                action  => "get",
                thing   => "alertgroup",
                status  => "ok",
                stimer  => $servertime,
                data    => {
                    alerts      => \@data,
                    header      => \@displaycolumns,
                    flairdata   => $flair_href,
                    entries     => \@entries,
                },
            },
        );
        $activitystatus = "ok";
    }
    else {
        $self->render(
            json    => {
                title   => "Alertgroup Member List",
                action  => "get",
                thing   => "alertgroup",
                status  => "no matching records",
                stimer  => $servertime,
            }
        );
        $activitystatus = "failed";
    }
    #$self->update_activity_log({
    #    what    => "viewed alertgroup list",
    #    when    => time(),
    #    xid     => 0,
    #    type    => "view",
    #    data    => {
    #        target_type => "alertgroup",
    #        match_ref   => { alertgroup_id => $alertgroup_id },
    #        status      => $activitystatus,
    #    },
    #});
}

=item C<get_alertgroup_status>
 this function updated the gridview line with any changes that may hav
 occurred in the member alerts
=cut
sub get_alertgroup_status {
    my $self    = shift;
    my $log     = $self->app->log;
    my $mongo   = $self->mongo;
    my $timer   = $self->get_timer("get_alertgroup_status");
    
    my $alertgroup_id   = $self->stash("id") + 0;

    $log->debug("Refreshing Alertgroup $alertgroup_id Status");

    my $status_href = {
        title   => "Alertref Status",
        action  => "get",
        thing   => "alertgroup",
        status  => "ok",
    };

    my $alertgroup_object   = $mongo->read_one_document({
        collection  => "alertgroups",
        match_ref   => { alertgroup_id => $alertgroup_id },
    });

    if ($alertgroup_object) {
        #my ( $status,
        #     $alert_ids_aref,
        #     $tags_aref ) = $self->get_alertgroup_data($alertgroup_id);

        my $agdata_href = $self->get_alertgroup_data($alertgroup_id);

        $alertgroup_object->status($agdata_href->{status});
        $alertgroup_object->closed($agdata_href->{closed});
        $alertgroup_object->promoted($agdata_href->{promoted});
        $alertgroup_object->total($agdata_href->{total});
        $alertgroup_object->add_to_set("alert_ids", $agdata_href->{alerts});
        $alertgroup_object->add_to_set("tags",      $agdata_href->{tags});
        $mongo->update_document($alertgroup_object);

        $status_href->{data} = {
            alertgroup_id       => $alertgroup_id,
            status              => $alertgroup_object->status,
            closed              => $alertgroup_object->closed,
            promoted            => $alertgroup_object->promoted,
            total               => $alertgroup_object->total,
            updated             => $alertgroup_object->updated,
            created             => $alertgroup_object->created,
            source              => $alertgroup_object->source,
            subject             => $alertgroup_object->subject,
            tags                => join(',', sort @{$alertgroup_object->tags}),
            views               => $alertgroup_object->view_count,
            viewed_by           => $alertgroup_object->viewed_by,
            alertcount          => scalar(@{$alertgroup_object->alert_ids}),
        };
    }
    else {
        $status_href->{status}  = "failed";
        $status_href->{data}    = "no matching alertgroup";
    }
    $status_href->{stime}   = &$timer;
    $self->render( json => $status_href );
}

sub get_alertgroup_data {
    my $self    = shift;
    my $id      = shift;
    my $log     = $self->app->log;
    my $mongo   = $self->mongo;
    my $timer   = $self->get_timer("get_alertgroup_data");

    $log->debug("Getting alertgroup data for alertgroup $id");

    my $cursor  = $mongo->read_documents({
        collection  => "alerts",
        match_ref   => { alertgroup => $id },
    });

    my $closed      = 0;
    my $open        = 0;
    my $promoted    = 0;
    my $total       = 0;
    my @ids     = ();
    my @tags    = ();

    while ( my $object  = $cursor->next ) {
        my $idfield     = $object->idfield;
        my $alert_id    = $object->$idfield;
        my $status      = $object->status;
        my $tags_aref   = $object->tags;

        push @ids,  $alert_id;
        push @tags, @$tags_aref;
        $closed++ if ( $status eq "closed");
        $open++ if ( $status eq "open" );
        $promoted++ if ( $status eq "promoted");
        $total++;
    }

    my $status = "closed";
    if ($open > 0 ) { $status = "open"; }
    if ($promoted > 0 ) { $status = "promoted"; } 

    

    &$timer;
    return {
        status  => $status, 
        alerts  => \@ids, 
        tags    => \@tags,
        closed  => $closed,
        promoted=> $promoted,
        total   => $total,
    }
}

sub update_alertgroup {
    my $self    = shift;    
    my $log     = $self->app->log;
    my $mongo   = $self->mongo;
    my $id      = $self->stash('id') + 0;
    my $timer   = $self->get_timer("update_alertgroup");
    my $req     = $self->req;
    my $json    = $req->json;

    $log->debug("updating alertgroup $id");

    my $status_href = {
        action  => "post",
        thing   => "alertgroup",
        id      => $id,
        status  => "ok",
    };

    my $ag_object   = $mongo->read_one_document({
        collection  => "alertgroups",
        match_ref   => { alertgroup_id => $id },
    });

    if ( $ag_object ) {
        my $mod_href        = $ag_object->build_modification_cmd($self);
        my $alert_mod_href  = $mod_href->{alerts};

        $log->debug("applying modification to alerts");

        if ( $mongo->apply_update($alert_mod_href, { safe=>1, multiple=>1 }) ){
            $log->debug("applied modification alerts");
        }

        my $ag_mod_href     = $mod_href->{alertgroups};
        # my ( $newstatus, $jaref1, $jaref2 ) = $self->get_alertgroup_data($id);
        my $agdata_href = $self->get_alertgroup_data($id);
        $ag_mod_href->{data_ref}->{'$set'}->{status} = $agdata_href->{status};

        $log->debug("applying modification to alergroup");
        $log->debug(Dumper($ag_mod_href));

        if ( $mongo->apply_update($ag_mod_href) ){
            $log->debug("applied modification to alertgroup");
            $self->notify_activemq({
                type    => "alertgroup",
                id      => $id,
                action  => "update",
            });
        }

        $self->update_activity_log({
            who     => $self->session('user'),
            what    => "updated alertgroup $id",
            when    => time(),
            xid     => 0,
            type    => "update",
            data    => {
                target_id   => $id,
                target_type => "alertgroup",
                original_obj=> $ag_object->as_hash,
            },
        });
    }
    else {
        $status_href->{status} = "fail";
    }
    $status_href->{stime} = &$timer;
    $self->render( json => $status_href );
}

sub delete_alertgroup {
    my $self    = shift;
    my $log     = $self->app->log;
    my $mongo   = $self->mongo;
    my $id      = $self->stash('id') + 0;
    my $timer   = $self->get_timer("delete_alertgroup");
    my %status;

    $log->debug("Deleting Alertgroup $id");

    my $alertgroup_obj  = $mongo->read_one_document({
        collection  => "alertgroups",
        match_ref   => { alertgroup_id => $id } ,
    });

    if ( $mongo->delete_document($alertgroup_obj) ) {
        $status{alertgroup} = "ok";
        $self->notify_activemq({
            type    => "alertgroup",
            id      => $id,
            action  => "deletion",
        });
    }
    else {
        $status{alertgroup} = "alreadygone";
    }

    my $cursor  = $mongo->read_documents({
        collection  => "alerts",
        match_ref   => { alertgroup => $id },
    });

    while ( my $alert_obj = $cursor->next ) {
        my $alert_id    = $alert_obj->alert_id;

        if ( $alert_obj->is_modifiable($self->session('groups')) ) {
            if ( $mongo->delete_document($alert_obj) ) {
                $status{alert}{$alert_id} = "ok";
                $alert_obj->remove_self_from_entities($mongo);
                #NRP Elastic remove
	        $self->notify_activemq({
                    type    => "alert",
                    id      => $alert_id,
                    action  => "deletion",
                });
            }
            else {
                $status{alert}{$alert_id} = "failed";
            }
        }
    }
    my $stime   = &$timer;

    $self->render(
        json    => {
            title   => "Delete Alertgroup",
            action  => 'delete',
            thing   => 'alertgroup',
            status  => \%status,
            stimer  => $stime,
        }
    );
    $self->update_activity_log({
        who     => $self->session('user'),
        what    => "deleted alertgroup $id",
        when    => $self->timestamp(),
        xid     => 0,
        type    => "deletion",
        data    => {
            target_id   => $id,
            target_type => "alertgroup",
            status      => \%status,
            alerts      => [ keys %{$status{alert}}],
        },
    });
}

sub get_flair_data {
    my $self            = shift;
    my $entities_aref   = shift;
    my $mongo           = $self->mongo;
    my $log             = $self->app->log;
    my $timer           = $self->get_timer("get_flair_data");

    $log->debug("Getting Flair Data for Alertgroup");

    my @values  = map { $_->{value} } @$entities_aref;

    my $cursor  = $mongo->read_documents({
        collection  => "entities",
        match_ref   => { value => { '$in' => \@values }},
    });

    my %data = ();

    while ( my $entity = $cursor->next ) {
        $entity->update_data;
        my $value   = $entity->value;
        $data{$value} = {
            entity_id   => $entity->entity_id + 0,
            entity_type => $entity->entity_type,
            notes       => $entity->notes,
            geo_data    => $entity->geo_data,
            block_data  => $entity->block_data,
            reputation  => $entity->reputation,
            alerts      => $self->get_count($entity->alerts),
            events      => $self->get_count($entity->events),
            incidents   => $self->get_count($entity->incidents),
        };
    }
    &$timer;

    $log->debug("Flairdata : ". Dumper(\%data));
    return \%data;
}

sub get_count {
    my $self    = shift;
    my $aref    = shift;

    if (defined $aref ) {
        return scalar(@{$aref});
    }
    return 0;
}



            
1;
