package Scot::Collection::Alertgroup;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;

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

=item B<create_from_api($request_href)>

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
    my %columns         = ();
            
    foreach my $alert_href (@$data) {

        my $chref   = {
            data        => $alert_href,
            alertgroup  => $id,
            status      => 'open',
        };

        $log->trace("Creating alert ", {filter=>\&Dumper, value => $chref});

        my $alert = $mongo->collection("Alert")->create($chref);

        unless ( defined $alert ) {
            $log->error("Failed to create Alert from ",
                         { filter => \&Dumper, value => $chref });
            next;
        }

        $mq->send("scot", {
            action  => "created", 
            data    => {
                type        => "alert",
                id          => $alert->id,
                who         => $request->{user},
            }
        });

        # not sure we need a notification for every alert, maybe just alertgroup
        # alert triage may want this at some point though
        # $env->amq->send_amq_notification("creation", $alert);

        $alert_count++;
        $open_count++       if ( $alert->status eq "open" );
        $closed_count++     if ( $alert->status eq "closed" );
        $promoted_count++   if ( $alert->status eq "promoted");
    }

    $alertgroup->update({
        '$set'  => {
            open_count      => $open_count,
            closed_count    => $closed_count,
            promoted_count  => $promoted_count,
            alert_count     => $alert_count,
        }
    });
    $self->env->mq->send("scot",{
        action  => "created", 
        data    => {
            type    => "alertgroup",
            id      => $alertgroup->id
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

    $log->trace("[Alertgroup $id] sending activemq update message");

    $env->mq->send("scot", {
        action  => "updated", 
        data    => {
            type    => "alertgroup",
            id      => $id, 
            who     => $user
        }
    });
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
            my $update  = {
                id  => $alert->id,
            };
            if ( $request->{status} ) {
                $update->{status} = $request->{status};
            }
            if ( $request->{parsed} ) {
                $update->{parsed} = $request->{parsed};
            }
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
            

1;
