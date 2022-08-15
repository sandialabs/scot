package Scot::Collection::Event;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;

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

=item B<api_create($api_ref)>

Create an event and from a POST to the handler

=cut

override api_create => sub {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $self->log;

    $log->trace("Create Event from API");

    my $user    = $request->{user};
    my $json    = $request->{request}->{json};

    if ( defined $user ) {
        $json->{owner} = $user;
    }

    my @tags    = $env->get_req_array($json, "tags");
    my @sources = $env->get_req_array($json, "sources");

    if ( defined $json->{from_alerts} ) {
        $self->process_alerts($request);
    }

    my $entry_body = $request->{entry};
    delete $request->{entry};

    $self->validate_permissions($json);

    my $event   = $self->create($json);

    unless ($event) {
        $log->error("ERROR creating Event from ",
            { filter => \&Dumper, value => $request});
        return undef;
    }

    if ($entry_body) {
        $self->create_event_entry($event, $entry_body);
    }

    my $id      = $event->id;
    if ( scalar(@sources) > 0 ) {
        my $col = $self->meerkat->collection('Source');
        $col->add_source_to("event", $event->id, \@sources);
    }
    if ( scalar(@tags) > 0 ) {
        my $col = $self->meerkat->collection('Tag');
        $col->add_source_to("event", $event->id, \@tags);
    }

    return $event;
};

sub create_event_from_message {
    my $self    = shift;
    my $data    = shift;
    my $log     = $self->log;
    my $env     = $self->env;

    my $event_data  = $data->{event};
    my $entry_data  = $data->{entry};

    my $event   = $self->create($event_data);

    if ( ! defined $event ) {
        $log->error("Failed to create Event from ",
                    {filter=>\&Dumper, value=>$event_data});
        return 0;
    }
    my @tags    = @{$event_data->{tags}};
    my @sources = @{$event_data->{source}};

    if ( $entry_data ) {
        $self->create_event_entry($event, $entry_data->{body});
    }
    my $id      = $event->id;
    if ( scalar(@sources) > 0 ) {
        my $col = $self->meerkat->collection('Source');
        $col->add_source_to("event", $event->id, \@sources);
    }
    if ( scalar(@tags) > 0 ) {
        my $col = $self->meerkat->collection('Tag');
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

sub create_event_entry {
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
        groups  => $event->groups,
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
    my $mongo       = $self->meerkat;
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
    $build_href->{readgroups} = $self->defaults->{default_groups}->{read}
        unless $build_href->{readgroups};
    $build_href->{modifygroups} = $self->defaults->{default_groups}->{modify}
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
    my $user    = $req->{user};
    my $subject =   $self->get_subject($object) //
                    $self->get_value_from_request($req, "subject");

    return $self->create({
        subject => $subject, 
        status  => 'open',
        owner   => $user,
        promoted_from => [ $object->id ],
    });
}

sub get_subject {
    my $self    = shift;
    my $object  = shift;
    
    if ( ref($object) eq "Scot::Model::Alert" ) {
        my $agid    = $object->alertgroup;
        my $agcol   = $self->meerkat->collection('Alertgroup');
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

sub api_subthing {
    my $self    = shift;
    my $req     = shift;
    my $mongo   = $self->meerkat;
    my $log     = $self->log;

    my $thing       = $req->{collection};
    my $subthing    = $req->{subthing};
    my $id          = $req->{id}+0;

    if ( $subthing eq "alert" ) {
        $log->debug("getting alert subthing");
        my $event   = $self->find_iid($id);
        $log->debug("event type is ".ref($event));
        my $ehash = $event->as_hash;
        $log->debug("event is ",{filter=>\&Dumper, value=>$ehash});
        return $mongo->collection('Alert')->find({
            id => { '$in' => $event->promoted_from }
        });
    }

    if ($subthing eq "incident" ) {
        return $mongo->collection('Incident')->find({promoted_from => $id});
    }

    if ( $subthing eq "entry" ) {
        return $mongo->collection('Entry')->get_entries_by_target({
            id      => $id,
            type    => 'event',
        });
    }
    if ( $subthing eq "link" ) {
        return $mongo->collection('Link')
                    ->get_links_by_target({
                        id      => $id,
                        type    => $thing,
                    });
    }

    if ( $subthing eq "entity" ) {
        return $mongo->collection('Link')
                     ->get_linked_objects_cursor(
                        { id => $id, type => 'event' },
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
                type            => 'tag',
                'target.type'   => 'event',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Tag')->find({
            id  => { '$in' => \@appearances }
        });
    }
    if ( $subthing eq "source" ) {
        my @appearances = map { $_->{apid} }
            $mongo->collection('Appearance')->find({
                type            => 'source',
                'target.type'   => 'event',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Source')->find({
            id  => { '$in' => \@appearances }
        });
    }

    if ( $subthing eq "history" ) {
        return $mongo->collection('History')->find({
            'target.id'   => $id,
            'target.type' => 'event'
        });
    }

    if ( $subthing eq "file" ) {
        return $mongo->collection('File')->find({
            'entry_target.id'     => $id,
            'entry_target.type'   => 'event',
        });
    }

    die "Unsupported subthing $subthing";

}

## issue 401 requests that if the analyst tries to promote to a non-existant
## event, that it should error instead of create the non-existant object
sub get_promotion_obj {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    my $promotion_id    = $req->{request}->{json}->{promote} 
                          // $req->{request}->{params}->{promote};

    $log->debug("Getting promotion object: $promotion_id from ",
                {filter => \&Dumper, value => $req});
    $log->debug("The object being promoted is a ".ref($object));

    my $event;

    if ( $promotion_id =~ /\d+/ ) { 
        $event = $self->find_iid($promotion_id);
        if ( defined $event and ref($event) eq "Scot::Model::Event" ) {
            return $event;
        }
        else {
            die "Event $promotion_id does not exists.  Can not promote to non-existant event!";
        }
    }

    if ( $promotion_id eq "new" or ! defined $promotion_id ) {
        # no promotion id provided, so let's create the event
        $event   = $self->create_promotion($object, $req);
        return $event;
    }

    die "Invalid promotion id";
}

sub autocomplete {
    my $self    = shift;
    my $frag    = shift;
    my $cursor  = $self->find({
        subject => /$frag/
    });
    my @records = map { {
        id  => $_->{id}, key => $_->{subject}
    } } $cursor->all;
    return wantarray ? @records : \@records;
}

sub get_by_msgid {
    my $self    = shift;
    my $msgid   = shift;
    my $log     = $self->log;
    my $query   = {
        'data.message_id'   => $msgid
    };
    $log->debug("get_by_msgid query = ",{filter=>\&Dumper, value=>$query});

    my $event = $self->find_one($query);
    return $event;
}


1;
