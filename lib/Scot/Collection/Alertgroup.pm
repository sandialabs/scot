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
    my $row_limit   = $env->get_config_item("row_limit")//200;
    my @ag_requests = ();
    my $parts       = int($alert_rows/$row_limit);
    my $remainder   = $alert_rows % $row_limit;
    if ( $remainder != 0 ) {
        $parts += 1;
    }
    my $page        = 1;

    while ( my @subalerts = splice(@$data, 0, $row_limit) ) {
        my $sub = $href->{request}->{json}->{subject};
        $sub .= " (part $page of $parts)" if ($parts != 1);
        my $new = dclone($href);
        $new->{request}->{json}->{subject} = $sub;
        push @{$new->{request}->{json}->{data}}, @subalerts;
        push @ag_requests, $new;
        $page++;
    }

    $log->debug("Alertgroup was split into ".scalar(@ag_requests)." pieces");
    return wantarray ? @ag_requests : \@ag_requests;
}

override api_create => sub {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my @mq_msgs     = ();
    my @audit_msgs  = ();
    my @stat_msgs   = ();

    $log->trace("create alertgroup");

    # alertgroup creation will receive the following in the 
    # json portion of the request
    # request => {
    #    message_id  => '213123',
    #    subject     => 'subject',
    #    data       => [ { ... href structure ...      }, { ... } ... ],
    #    tags       => [],
    #    sources    => [],
    # }

    my @requests        = $self->split_alertgroups($href);
    my @alertgroups     = ();

    REQUEST:
    foreach my $request (@requests) {
        my $tags        = $request->{request}->{json}->{tag};
        my $sources     = $request->{request}->{json}->{source};
        my $data        = delete $request->{request}->{json}->{data};
        my $alertgroup  = $self->create($request->{request}->{json});
        my $alertscreated   = 0;

        if ( ! defined $alertgroup ) {
            $log->error("Failed to create alertgroup with data ",
                        { filter => \&Dumper, value => $request });
            next REQUEST;
        }
        my $id          = $alertgroup->id;

        my $alert_col   = $mongo->collection('Alert');

        $log->trace("Creating alerts belonging to Alertgroup ". $id);
        foreach my $datum (@{$data}) {

            my $alertscreated += $alert_col->api_create({
                data        => $datum,
                alertgroup  => $id,
                columns     => $alertgroup->columns,
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

=item B<create_from_api(request_href)>

Create an alertgroup and sub alerts from a POST to the handler

=cut

sub create_from_api {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $mq      = $env->mq;

    $log->trace("Create Alertgroup");

    # alertgroup creation will receive the following in the 
    # json portion of the request
    # request => {
    #    message_id  => '213123',
    #    subject     => 'subject',
    #    data       => [ { ... href structure ...      }, { ... } ... ],
    #    tags       => [],
    #    sources    => [],
    # }

    my $request = $href->{request}->{json};

    my $data    = $request->{data};
    delete $request->{data};

    if ( ref($data) ne "ARRAY" ) {
        push @$data, $data;
    }

    my $row_limit = 200;
    #if ( defined $env->alertgroup_rowlimit ) {
    #    $row_limit = $env->alertgroup_rowlimit;
    #    $log->debug("Altername rowlimit specified as ".$row_limit);
    #}

    if ( scalar(@$data) > $row_limit ) {
        $log->warn("Large number of rows in Alertgroup, splitting...");
        my @created_alertgroup;

        my $x = 1;
        my $subject = $href->{request}->{json}->{subject};
        while ( my @subalerts = splice(@$data, 0, $row_limit) ) {
            push @{$href->{request}->{json}->{data}}, @subalerts;
            $href->{request}->{json}->{subject} = $subject . " part $x";
            $log->debug("splitting alertgroup : ",
                        {filter=>\&Dumper, value => $href});
            push @created_alertgroup, $self->create_from_api($href);
            $x++;
        }
        return \@created_alertgroup;
    }

    my $tags    = $request->{tags};
    # delete $request->{tags};  # store a copy here and there

    my $sources = $request->{sources};
    # delete $request->{sources}; # store a copy in obj and in sources.pm

    my $alertgroup  = $self->create($request);

    unless ( defined $alertgroup ) {
        $log->error("Failed to create Alertgroup with data ",
                    { filter => \&Dumper, value => $request});
        return undef;
    }

    my $id          = $alertgroup->id;

    if ( defined $tags && scalar(@$tags) > 0 ) {
        my $col = $mongo->collection('Tag');
        foreach my $tag (@$tags) {
            my $t = $col->add_tag_to("alertgroup",$id, $tag);
        }
    }

    if ( defined $sources && scalar(@$sources) > 0 ) {
        my $col = $mongo->collection('Source');
        foreach my $src (@$sources) {
            my $s = $col->add_source_to("alertgroup", $id, $src);
        }
    }

    $log->trace("Creating alerts belonging to Alertgroup ". $id);

    my $alert_count     = 0;
    my $open_count      = 0;
    my $closed_count    = 0;
    my $promoted_count  = 0;
            
    foreach my $alert_href (@$data) {

        my $chref   = {
            data        => $alert_href,
            alertgroup  => $id,
            status      => 'open',
            columns     => $alertgroup->columns,
        };



        $log->debug("Creating alert ", {filter=>\&Dumper, value => $chref});

        my $alert = $mongo->collection("Alert")->create($chref);

        unless ( defined $alert ) {
            $log->error("Failed to create Alert from ",
                         { filter => \&Dumper, value => $chref });
            next;
        }

        # amq stuff should originate out of Api.pm
        #$mq->send("scot", {
        #    action  => "created", 
        #    data    => {
        #        type        => "alert",
        #        id          => $alert->id,
        #        who         => $request->{user},
        #    }
        #});

        # not sure we need a notification for every alert, maybe just alertgroup
        # alert triage may want this at some point though
        # $env->amq->send_amq_notification("creation", $alert);

        $alert_count++;
        $open_count++       if ( $alert->status eq "open" );
        $closed_count++     if ( $alert->status eq "closed" );
        $promoted_count++   if ( $alert->status eq "promoted");
    }

    $log->debug("updating alertgroup ", $alertgroup->id);

    $alertgroup->update({
        '$set'  => {
            open_count      => $open_count,
            closed_count    => $closed_count,
            promoted_count  => $promoted_count,
            alert_count     => $alert_count,
        }
    });
    return $alertgroup;
}

sub refresh_data {
    my $self    = shift;
    my $id      = shift;
    my $user    = shift // "api";
    my $env     = $self->env;
    my $mq      = $env->mq;
    my $log     = $env->log;

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

#    $log->trace("[Alertgroup $id] sending activemq update message");
#    $env->mq->send("scot", {
#        action  => "updated", 
#        data    => {
#            type    => "alertgroup",
#            id      => $id, 
#            who     => $user
#        }
#    });
}

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
        # build array of entity ids linked to this alertgroup
        my @links = map { $_->{entity_id} } 
            $mongo->collection('Link')->get_links_by_target({
                id  => $id, type => 'alertgroup'
            })->all;
        # return all matching entities
        return $mongo->collection('Entity')->find({
            id  => { '$in' => \@links }
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
        return $mongo->collection('Guide')->find({applies_to => $ag->subject});
    }

    if ( $subthing eq "history") {
        return $mongo->collection('History')->find({
            'target.id'   => $id,
            'target.type' => 'alertgroup',
        });
    }

    die "Unsupported subthing: $subthing";
}
    

override get_subthing => sub {
    my $self        = shift;
    my $thing       = shift;
    my $id          = shift;
    my $subthing    = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;

    $id += 0;

    if ( $subthing  eq "alert" ) {
        my $col = $mongo->collection('Alert');
        my $cur = $col->find({alertgroup => $id});
        return $cur;
    }
    elsif ( $subthing eq "entry" ) {
        my $col = $mongo->collection('Entry');
        my $cur = $col->get_entries_by_target({
            id      => $id,
            type    => 'alertgroup'
        });
        return $cur;
    }
    elsif ( $subthing eq "entity" ) {
        my $timer  = $env->get_timer("fetching links");
        my $col    = $mongo->collection('Link');
        my $ft  = $env->get_timer('find actual timer');
        my $cur    = $col->get_links_by_target({ 
            id => $id, type => 'alertgroup' 
        });
        &$ft;
        my @lnk = map { $_->{entity_id} } $cur->all;
        &$timer;

        $timer  = $env->get_timer("generating entity cursor");
        $col    = $mongo->collection('Entity');
        $cur    = $col->find({id => {'$in' => \@lnk }});
        &$timer;
        return $cur;
    }
    elsif ( $subthing eq "tag" ) {
        my $col = $mongo->collection('Appearance');
        my $cur = $col->find({
            type            => 'tag',
            'target.type'   => 'alertgroup',
            'target.id'     => $id,
        });
        my @ids = map { $_->{apid} } $cur->all;
        $col    = $mongo->collection('Tag');
        $cur    = $col->find({ id => {'$in' => \@ids }});
        return $cur;
    }
    elsif ( $subthing eq "source" ) {
        my $col = $mongo->collection('Appearance');
        my $cur = $col->find({
            type            => 'source',
            'target.type'   => 'alertgroup',
            'target.id'     => $id,
        });
        my @ids = map { $_->{apid} } $cur->all;
        $col    = $mongo->collection('Source');
        $cur    = $col->find({ id => {'$in' => \@ids }});
        return $cur;
    }
    elsif ( $subthing eq "guide" ) {
        my $ag  = $self->find_iid($id);
        my $col = $mongo->collection('Guide');
        my $cur = $col->find({applies_to => $ag->subject});
        return $cur;
    }
    elsif ( $subthing eq "history" ) {
        my $col = $mongo->collection('History');
        my $cur = $col->find({'target.id'   => $id,
                              'target.type' => 'alertgroup',});
        return $cur;
    }
    else {
        $log->error("unsupported subthing $subthing!");
    }
};

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
    $log->debug("Found ". $cur->count. " matches");

    while (my $alert = $cur->next) {
        my $ahref   = $alert->as_hash;
        push @{ $href->{alerts} }, $ahref;
    }
    return $href;
}

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


sub update_alertgroup_with_bundled_alert {
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
        my $entities    = delete $alert->{entities};
        if ( $alert_obj->update({'$set' => $alert}) ) {
            $log->debug("updated alert $alert_id");
            if ( defined $entities and scalar(@$entities) > 0 ) {
                $mongo->collection('Entity')
                      ->update_entities($alert_obj, $entities);
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

1;

