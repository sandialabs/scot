package Scot::Collection::Event;
use lib '../../../lib';
use Moose 2;

extends 'Scot::Collection';

with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

=head1 Name

Scot::Collection::Event

=head1 Description

Custom collection operations for Events

=head1 Methods

=over 4

=item B<create_from_api($api_ref)>

Create an event and from a POST to the handler

=cut


sub create_from_api {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Create Event from API");

    my $user    = $request->{user};
    my $json    = $request->{request}->{json};

    my @tags    = $env->get_req_array($json, "tags");
    my @sources = $env->get_req_array($json, "sources");

    if ( defined $json->{from_alerts} ) {
        $self->process_alerts($request);
    }

    my $entry_body = $request->{entry};
    delete $request->{entry};

    my $event   = $self->create($json);

    unless ($event) {
        $log->error("ERROR creating Event from ",
            { filter => \&Dumper, value => $request});
        return undef;
    }

    if ($entry_body) {
        $self->create_alert_entry($event, $entry_body);
    }

    my $id      = $event->id;
    if ( scalar(@sources) > 0 ) {
        my $col = $env->mongo->collection('Source');
        $col->add_source_to("event", $event->id, \@sources);
    }
    if ( scalar(@tags) > 0 ) {
        my $col = $env->mongo->collection('Tag');
        $col->add_source_to("event", $event->id, \@tags);
    }

    return $event;
}

sub process_alerts {
    my $self    = shift;
    my $bhref   = shift;
    my $env     = $self->env;
    my $mongo   = $self->meerkat;

    my $alerts_aref = $bhref->{from_alerts};
    delete $bhref->{from_alerts};
    my $cursor      = $mongo->collection("Alert")->find({
        id  => { '$in'  => $alerts_aref }
    });

    my @alertids    = ();
    my $body        = "";

    while ( my $alert   = $cursor->next ) {
        my $id  = $alert->id;
        my $ag  = $alert->alertgroup;
        push @alertids, $id;
        $body = $self->add_to_body($body, $alert);
    }

    $bhref->{entry}    = $body;
    $bhref->{alerts}   = \@alertids;
}

sub create_alert_entry {
    my $self    = shift;
    my $event   = shift;
    my $body    = shift;
    my $env     = $self->env;
    my $mongo   = $self->meerkat;
    my $entry_href = {
        target      => {
            type => "event",
            id   => $event->id,
        },
        readgroups  => $event->readgroups,
        modifygroups=> $event->modifygroups,
        summary     => 0,
        body        => $body,
    };
    my $entrycol    = $mongo->collection('Entry');
    my $entry       = $entrycol->create($entry_href);

}

sub add_to_body {
    my $self    = shift;
    my $body    = shift;
    my $alert   = shift;
    my $id      = $alert->id;
    $body .= "<h4>Alert $id</h4>" . 
                "<table class=\"alert_in_entry\"><tr>".
                "  <th>ID</th>";

    foreach my $column (@{$alert->columns}) {
        $body .= "<th>" . $column . "</th>";
    }
    $body .= "</tr><tr>";

    $body .= "<th>".$id."</th>";
    foreach my $column (@{$alert->columns}) {
        $body .= "<th>". $alert->data_with_flair->{$column} . "</th>";
    }
    $body .= "</tr><table>";
    return $body;
}


=item B<build_from_alerts>

given a set of alert_id's build an event

1. get alerts cursor
2. foreach
    a. get columns and flair data
    b. add to proto entry body
    c. set alert status to promoted
    d. update alertgroup status
    e. create entry 

=cut

sub build_from_alerts {
    my $self        = shift;
    my $handler     = shift;
    my $build_href  = shift;
    my $env         = $handler->env;
    my $mongo       = $env->mongo;
    my $alerts_aref = $build_href->{from_alerts};

    my $alert_col   = $mongo->collection("Alert");
    my $agcol       = $mongo->collection("Alertgroup");
    my $entrycol    = $mongo->collection("Entry");
    my $cursor      = $alert_col->find({id => {'$in' => $alerts_aref} });

    my $subject     = '';
    my $body        = "<h3>Original Alerts</h3>";
    my @alertgroups = ();
    my @alert_ids   = ();

    while (my $alert = $cursor->next ) {
        my $id  = $alert->id;
        my $ag  = $alert->alertgroup;
        push @alert_ids, $id;

        $body .= "<h4>Alert $id</h4>" . 
                   "<table class=\"alert_in_entry\"><tr>".
                   "  <th>ID</th>";

        foreach my $column (@{$alert->columns}) {
            $body .= "<th>" . $column . "</th>";
        }
        $body .= "</tr><tr>";

        $body .= "<th>".$id."</th>";
        foreach my $column (@{$alert->columns}) {
            $body .= "<th>". $alert->data_with_flair->{$column} . "</th>";
        }
        $body .= "</tr><table>";
        my $agobj   = $agcol->find_iid($ag);
        $agobj->update_set(status=>"promoted");
        $agobj->update_inc(promoted_count => 1);
        $agobj->update_inc($alert->status."_count" => -1);
        $subject = $agobj->subject;
        $alert->update_set( status => "promoted");
    }
    
    $build_href->{subject}  = $subject unless $build_href->{subject};
    $build_href->{status}   = "open" unless $build_href->{status};
    $build_href->{owner}    = $handler->session('user') 
        unless $build_href->{owner};
    $build_href->{readgroups} = $env->default_groups->{read}
        unless $build_href->{readgroups};
    $build_href->{modifygroups} = $env->default_groups->{modify}
        unless $build_href->{modifygroups};
    $build_href->{alerts} = \@alert_ids;
    delete $build_href->{from_alerts};

    my $event = $self->create($build_href);
    
    my $entry_href = {
        readgroups  => $build_href->{readgroups},
        modifygroups=> $build_href->{modifygroups},
        summary     => 0,
        body        => $body,
        target      => {
            type    => "event",
            id      => $event->id,
        },
    };
    my $entry   = $entrycol->create($entry_href);

    # TODO: I thing we need to add activemq calls here...

    return $event;
}

sub create_promotion {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $subject =   $self->get_subject($object) //
                    $self->get_value_from_request($req, "subject");

    return $self->create({
        subject => $subject, 
        status  => 'open',
    });
}

sub get_subject {
    my $self    = shift;
    my $object  = shift;
    
    if ( ref($object) eq "Scot::Model::Alert" ) {
        my $agid    = $object->alertgroup;
        my $agcol   = $self->env->mongo->collection('Alertgroup');
        my $agobj   = $agcol->find_iid($agid);
        return $agobj->subject;
    }
    else {
        return $object->subject;
    }
}

override 'has_computed_attributes' => sub {
    my $self    = shift;
    return undef;
};

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
        my $event = $self->find_iid($id);
        my $col = $mongo->collection('Alert');
        my $cur = $col->find({ id => { '$in' => $event->promoted_from }});
        return $cur;
    }
    elsif ( $subthing eq "incident" ) {
        my $col = $mongo->collection('Incident');
        my $cur = $col->find({promoted_from => $id});
        return $cur;
    }
    elsif ( $subthing eq "entry" ) {
        my $col = $mongo->collection('Entry');
        my $cur = $col->get_entries_by_target({
            id      => $id,
            type    => 'alert'
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
            'target.type'   => 'event',
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
            'target.type'   => 'event',
            'target.id'     => $id,
        });
        my @ids = map { $_->{apid} } $cur->all;
        $col    = $mongo->collection('Source');
        $cur    = $col->find({ id => {'$in' => \@ids }});
        return $cur;
    }
    elsif ( $subthing eq "history" ) {
        my $col = $mongo->collection('History');
        my $cur = $col->find({'target.id'   => $id,
                              'target.type' => 'event',});
        return $cur;
    }
    else {
        $log->error("unsupported subthing $subthing!");
    }
};



1;
