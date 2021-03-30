package Scot::Collection::Alertgroup;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;
use Storable qw(dclone);

extends 'Scot::Collection';

with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

=head1 Name

Scot::Collection::Alertgroup

=head1 Description

Custom collection operations for Alertgroups

=head1 Extends

Scot::Collection

=head1 Methods

=over 4

=item B<api_create($request_href)>

Create an alertgroup, return relevant data to Api.pm module
(new way, to replace create_from_api)

=cut

sub split_alertgroups {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("splitting alertgroup");

    # strip data field and ensure it is an array
    my $data    = delete $href->{request}->{json}->{data};
    push @$data, $data if ( ref($data) ne "ARRAY" );
        
    my $alert_rows  = scalar(@$data);
    my $row_limit   = $env->get_config_item("row_limit") // 100;
    $log->debug("row limit is $row_limit");
    my @ag_requests = ();
    my $parts       = int($alert_rows/$row_limit);
    my $remainder   = $alert_rows % $row_limit;
    if ( $remainder != 0 ) {
        $parts += 1;
    }
    my $page        = 1;

    while ( my @subalerts = splice(@$data, 0, $row_limit) ) {
        $log->debug("sub alerts contain ".scalar(@subalerts)." rows");
        my $sub = $href->{request}->{json}->{subject};
        $sub .= " (part $page of $parts)" if ($parts != 1);
        my $new = dclone($href);
        $new->{request}->{json}->{subject} = $sub;
        $log->debug("creating $sub");
        push @{$new->{request}->{json}->{data}}, @subalerts;
        push @ag_requests, $new;
        $page++;
    }

    $log->debug("Alertgroup was split into ".scalar(@ag_requests)." pieces");
    return wantarray ? @ag_requests : \@ag_requests;
}

=item B<api_create($href)>

Overrides api_create in Scot::Collection.  Create an alertgroup from 

    # alertgroup creation will receive the following in the 
    # json portion of the request
    # request => {
    #    message_id  => '213123',
    #    subject     => 'subject',
    #    data       => [ { ... href structure ...      }, { ... } ... ],
    #    tags       => [],
    #    sources    => [],
    # }

=cut

override api_create => sub {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my @mq_msgs     = ();
    my @audit_msgs  = ();
    my @stat_msgs   = ();

    $log->debug("create alertgroup");


    my @requests        = $self->split_alertgroups($href);
    my @alertgroups     = ();

    $log->debug("REQUEST BE LIKE: ",{filter=>\&Dumper, value =>\@requests});

    REQUEST:
    foreach my $request (@requests) {
        my $tags        = $request->{request}->{json}->{tag};
        my $sources     = $request->{request}->{json}->{source};
        my $data        = delete $request->{request}->{json}->{data};
        my $json        = $request->{request}->{json};
        $self->validate_permissions($json);
        #if ( ! defined $request->{request}->{json}->{groups} ) {
        #    if ( defined $request->{groups} and 
        #         ref($request->{groups}) eq "ARRAY" and
        #         scalar(@{$request->{groups}}) > 0 ) {
        #            $request->{request}->{json}->{groups} = {
        #                read    => $request->{groups},
        #                modify  => $request->{groups},
        #            };
        #    }
        #    else {
        #        $request->{request}->{json}->{groups} = $env->default_groups;
        #    }
        #}
        my $alertgroup  = $self->create($json);
        my $alertscreated   = 0;

        if ( ! defined $alertgroup ) {
            $log->error("Failed to create alertgroup with data ",
                        { filter => \&Dumper, value => $request });
            next REQUEST;
        }
        my $id          = $alertgroup->id;

        my $alert_col   = $mongo->collection('Alert');

        $log->debug("Creating alerts belonging to Alertgroup ". $id);
        foreach my $datum (@{$data}) {

            my $alertscreated += $alert_col->linked_create({
                data        => $datum,
                subject     => $alertgroup->subject,
                alertgroup  => $id,
                columns     => $alertgroup->columns,
                owner       => $alertgroup->owner,
                groups      => $alertgroup->groups,
            });
        }

        $alertgroup->update({
            '$set'  => {
                open_count      => $alertscreated,
                closed_count    => 0,
                promoted_count  => 0,
                alert_count     => $alertscreated,
            }
        });

        push @alertgroups, $alertgroup;
    }
    return wantarray ? @alertgroups : \@alertgroups;
};


sub refresh_data {
    my $self    = shift;
    my $id      = shift;
    my $user    = shift // "api";
    my $env     = $self->env;
    my $mq      = $env->mq;
    my $log     = $env->log;

    ## TODO: see if we can move the mq stuff 
    ## recent bug:  flairer didn't have an mq stanza on a demo box
    ## so same code worked in prod but not on demo.  many hours of heartache
    ## later, I discover that flairer.pl is silently dying because $env->mq
    ## is not defined!

    $log->trace("[Alertgroup $id] Refreshing Data after Alert update");

    my $alertgroup  = $self->find_iid($id);

    unless ( $alertgroup ) {
        $log->error("[Alertgroup $id] NOT FOUND!");
        return;
        # die "Alertgroup $id not found!!!";
    }

    my $cursor  = $self->meerkat->collection('Alert')->find({alertgroup => $id});

    my %count   = (
        total       => 0,
        promoted    => 0,
        closed      => 0,
        open        => 0,
    );
    while ( my $alert = $cursor->next ) {
        $count{total}++;
        $count{$alert->status}++;
    }
    my $status;

    if ( $count{promoted} > 0 ) {
        $status = "promoted";
    }
    elsif ( $count{closed} == $count{total} ) {
        $status = "closed";
    }
    else {
        $status = "open";
    }

    $alertgroup->update({
        '$set'  => {
            open_count      => $count{open} // 0,
            closed_count    => $count{closed} // 0,
            promoted_count  => $count{promoted} // 0,
            alert_count     => $count{total},
            status          => $status,
            updated         => $env->now,
        }
    });

}

=item B<api_subthing($req)>

Given a $req that looks like:

    {
        collection  => thing,
        id          => 123,
        subthing    => subthing,
    }

return a cursor of subthings.

Valid subthings: alert, entry, entity, link, tag, source, guide, history

=cut

sub api_subthing {
    my $self    = shift;
    my $req     = shift;
    my $thing       = $req->{collection};
    my $id          = $req->{id} + 0;
    my $subthing    = $req->{subthing};
    my $mongo       = $self->env->mongo;

    $self->env->log->debug("api_subthing /$thing/$id/$subthing");

    if ( $subthing eq "alert") {
        return $mongo->collection('Alert')->find({
            alertgroup => $id
        });
    }

    if ( $subthing eq "entry") {
        return $mongo->collection('Entry')->get_entries_by_target({
            id      => $id,
            type    => 'alertgroup',
        });
    }

    if ( $subthing eq "entity" ) {
        return $mongo->collection('Link')
                     ->get_linked_objects_cursor(
                        { id => $id, type => 'alertgroup' },
                        'entity' );
    }

    if ( $subthing eq "link" ) {
        return $mongo->collection('Link')
                    ->get_links_by_target({
                        id      => $id,
                        type    => $thing,
                    });
    }

    if ( $subthing eq "tag" ) {
        my @appearances = map { $_->{apid} } 
            $mongo->collection('Appearance')->find({
                type    => 'tag', 
                'target.type'   => 'alertgroup',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Tag')->find({
            id => {'$in' => \@appearances}
        });
    }

    if ( $subthing eq "source" ) {
        my @appearances = map { $_->{apid} } 
            $mongo->collection('Appearance')->find({
                type    => 'source', 
                'target.type'   => 'alertgroup',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Source')->find({
            id => {'$in' => \@appearances}
        });
    }

    if ( $subthing eq "guide" ) {
        my $ag  = $mongo->collection('Alertgroup')->find_iid($id);
        return $mongo->collection('Guide')->find({
            'data.applies_to' => $ag->subject
        });
    }

    if ( $subthing eq "history") {
        return $mongo->collection('History')->find({
            'target.id'   => $id,
            'target.type' => 'alertgroup',
        });
    }

    die "Unsupported subthing: $subthing";
}

=item B<update_alerts_in_alertgroup($alertgroup_obj, $request_href)>

=cut

sub update_alerts_in_alertgroup {
    my $self     = shift;
    my $agobj    = shift;
    my $href     = shift;
    my $env      = $self->env;
    my $mongo    = $env->mongo;
    my $log      = $env->log;
    my $mq       = $env->mq;
    my $status   = { updated => [] };
    my $alertcol = $mongo->collection('Alert');
        
        # side effect in update_alet_in_group is the deletion of the keys
        # req_href->{request}->{data} and req_href->{request}->{alerts}

    $log->trace("Updating Alerts in Alertgroup");

    my $request = $href->{request}->{json};
    my $data    = delete $request->{data};
    unless ($data) {
        # might come in as $request->{alerts}
        $data   = delete $request->{alerts};
    }

    unless ($data) {
        $log->error("no alert updates in request");
        # check for a bulk status update, eg. closing all alerts
        # which comes in as /alertgroup/123 -d{status:"closed"}
        unless ( defined($request->{status}) or  defined($request->{parsed})) {
            return $status;
        }
        # yes, this means in this case two database calls, 
        # one here and then again to update, but
        # optimize later if this proves to be a slow down
        my $cursor = $alertcol->find({alertgroup => $agobj->id});
        while (my $alert = $cursor->next ) {
            my $update;
            $log->debug("request is ",{filter=>\&Dumper, value=>$request});
            $update->{id}  = $alert->id;
            if ( defined($request->{status}) ) {
                $update->{status} = $request->{status};
            }
            if ( defined($request->{parsed}) ) {
                $update->{parsed} = $request->{parsed};
            }
            $log->debug("adding to update: ",{filter=>\&Dumper, value=>$update});
            push @{$data}, $update;
        }
    }
    $log->debug("Update with ", {filter=>\&Dumper, value=>$data});

    ALERT:
    foreach my $alert_href (@$data) {
        my $alert_id    = delete $alert_href->{id};
        unless ($alert_id) {
            $log->error("can not update alert in alertgroup without alert id");
            push @{$status->{no_id}}, $alert_id;
            next ALERT;
        }
        $log->debug("Updating Alert $alert_id in Alertgroup ".$agobj->id);

        my $alertobj    = $alertcol->find_iid($alert_id);
        unless ($alertobj) {
            $log->error("Alert $alert_id not found!");
            push @{$status->{not_found}}, $alert_id;
            next ALERT;
        }
        unless ($alertobj->update({ '$set' => $alert_href })) {
            $log->error("Error applying update to ". $alertobj->id);
            push @{$status->{error}}, $alertobj->id;
        }
        else {
            push @{$status->{updated}}, $alertobj->id;
            $log->debug("Attemtping to write history for ".$alertobj->id);
            my $hist = {
                who     => $href->{user},
                what    => "Alert status changed to ".$alert_href->{status},
                when    => $env->now(),
                target  => { id => $alertobj->id, type => "alert" },
            };
            $self->env->mongo->collection("History")->add_history_entry($hist);
        }
    }
    return $status;
}

# used by old api
sub get_bundled_alertgroup {
    my $self    = shift;
    my $id      = shift;
    my $log     = $self->env->log;
    my $agobj   = $self->find_iid($id);
    my $href    = $agobj->as_hash;
       $href->{alerts} = [];
    my $col     = $self->env->mongo->collection('Alert');
    $id         += 0;
    my $match   = { alertgroup => $id };
    $log->debug("Looking for alerts in alertgroup $id");

    my $cur     = $col->find({alertgroup => $id});
    # deprecated cursor count
    # $log->debug("Found ". $cur->count. " matches");

    while (my $alert = $cur->next) {
        my $ahref   = $alert->as_hash;
        push @{ $href->{alerts} }, $ahref;
    }
    return $href;
}

=item B<get_alerts_in_alertgroup($alertgroup_object)>

return array of alerts for a given alertgroup

=cut

# new api 
sub get_alerts_in_alertgroup {
    my $self    = shift;
    my $object  = shift;
    my $id      = $object->id + 0;
    my $col     = $self->env->mongo->collection('Alert');
    my $cursor  = $col->find({alertgroup => $id});
    my @alerts  = ();

    while ( my $alert = $cursor->next ) {
        my $alert_href  = $alert->as_hash;
        push @alerts, $alert_href;
    }
    return wantarray ? @alerts : \@alerts;
}

=item B<update_alertgroup_with_bundled_alert($put_href)>

=cut

sub update_alertgroup_with_bundled_alert {
    my $self    = shift;
    my $putdata = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $alertcol    = $mongo->collection('Alert');
    my $entitycol   = $mongo->collection('Entity');

    $log->debug("updating alertgroup with bundled alerts");
    $log->debug("putdata = ",{filter=>\&Dumper, value=>$putdata});

    my $alertgroup_id   = delete $putdata->{id};
    my $alerts_aref     = delete $putdata->{alerts};

    if ( ! defined $alerts_aref ) {
        $log->error("No alerts bundled with alertgroup!");
        $alerts_aref    = [];
    }

    foreach my $alert (@{$alerts_aref}) {
        my $alert_id    = $alert->{id} + 0;

        $log->debug("Processing bundled alert $alert_id");

        my $entity_aref = delete $alert->{entities};

        $log->debug("Entities in alert: ",
                    {filter=>\&Dumper, value=>$entity_aref});

        my $alert_obj   = $alertcol->find_iid($alert_id);

        if ( ! defined $alert_obj or 
             ref($alert_obj) ne "Scot::Model::Alert" ) {
            $log->error("ALERT OBJECT Not FOUND!!!");
            die "Alert object $alert_id in alertgroup $alertgroup_id not found";
            # why though?
        }

        if ( defined $entity_aref and ref($entity_aref) eq "ARRAY" ) {
            $entitycol->update_entities($alert_obj, $entity_aref);
        }
        else {
            $log->warn("No Entities present");
        }

        $alert_obj->update({'$set' => {
            parsed  => 1,
            data_with_flair => $alert->{data_with_flair},
        }});
    }

    my $cmd = { '$set'  => $putdata };
    $log->debug("updating alertgroup with :",
                {filter=>\&Dumper,value=>$putdata});
    my $alertgroup  = $self->find_iid($alertgroup_id);

    if (! defined $alertgroup or 
        ref($alertgroup) ne "Scot::Model::Alertgroup") {
        $log->error("Can not find Alertgroup $alertgroup_id!");
        die "No Alertgroup to update!";
    }
    $alertgroup->update($cmd);
}

sub update_alertgroup_with_bundled_alert_old {
    my $self    = shift;
    my $putdata = shift;
    my $env      = $self->env;
    my $mongo    = $env->mongo;
    my $log      = $env->log;

    my $alertgroup_id = delete $putdata->{id};
    my $alertgroup    = $self->find_iid($alertgroup_id);

    unless ( $alertgroup ) {
        $log->error("Unable to find alertgroup $alertgroup_id");
        return undef;
    }

    my $alerts  = delete $putdata->{alerts};
    unless ($alerts) {
        $log->warn("No Alerts in Alertgroup!");
    }

    my $alertcol    = $mongo->collection('Alert');

    foreach my $alert (@$alerts) {
        my $alert_id    = $alert->{id} + 0;
        my $alert_obj   = $alertcol->find_iid($alert_id);

        if ( ! defined $alert_obj ) {
            $log->error("unable to get alert $alert_id object to update!");
        }

        my $entities    = delete $alert->{entities};
        if ( $alert_obj->update({'$set' => $alert}) ) {
            $log->debug("updated alert $alert_id");
            if ( defined $entities and scalar(@$entities) > 0 ) {
                $mongo->collection('Entity')
                      ->update_entities($alert_obj, $entities);
            }
            else {
                $log->error("NO ENTITIES");
            }
        }
        else {
            $log->error("failed to update alert $alert_id");
        }
    }

    my $cmd = { '$set' => $putdata };
    $log->debug("updating alertgroup with : ",{filter=>\&Dumper, value=>$cmd});
    if ( $alertgroup->update($cmd) ) {
        $log->debug("updated alertgroup");
    }
    else {
        $log->error("failed to update alertgroup");
    }
}

=item B<get_subject($alertgroup_id)>

return the subject of an alertgroup

=cut

sub get_subject {
    my $self    = shift;
    my $agid    = shift;

    my $agobj   = $self->find_iid($agid);
    if (defined $agobj) {
        return $agobj->subject;
    }
    die "Can't find Alertgroup $agid";
}

sub get_by_msgid {
    my $self    = shift;
    my $msgid   = shift;
    my $ag      = $self->find_one({message_id => $msgid});
    return $ag;
}

=back

=cut

1;

