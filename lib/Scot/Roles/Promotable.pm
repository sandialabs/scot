package Scot::Roles::Promotable;

use Moose::Role;
use Data::Dumper;
use namespace::autoclean;

=item C<promote_new>

 promote an alert to a new event 
 or an event to a new incident
 return new object

=cut

sub promote_new {
    my $self    = shift;
    my $log     = $self->log;

    my %functions   = (
        'Scot::Model::Alertgroup'   => 'promote_alertgroup',
        'Scot::Model::Alert'        => 'promote_alert',
        'Scot::Model::Event'        => 'promote_event',
    );

    my $mytype      = ref($self);
    my $function    = $functions{$mytype};
    
    if ( defined $function ) {
        return $self->$function();
    }
    $log->error("this objects type $mytype should not be promotable");
    return undef;
}

sub promote_alertgroup {
    my $self            = shift;
    my $env             = $self->env;
    my $mongo           = $env->mongo;
    my $log             = $env->app->log;
    my $alertgroup_id   = $self->alertgroup_id;

    $log->debug("Promoting an Alertgroup");

    my $event_href      = {
        readgroups      => $self->readgroups,
        modifygroups    => $self->modifygroups,
        status          => 'open',
        subject         => $self->subject,
        alerts          => $self->alert_ids,
        sources         => $self->sources,
        'log'           => $log,
        env             => $env,
    };
    # $log->debug("event_href is ".Dumper($event_href));
    my $event_object    = Scot::Model::Event->new($event_href);
    my $event_id        = $mongo->create_document($event_object);

    return $self->promote_alertgroup_to($event_object);
}

sub promote_alert {
    my $self            = shift;
    my $controller      = $self->controller;
    my $mongo           = $controller->mongo;
    my $log             = $controller->app->log;
    my $alert_id        = $self->alert_id;
    my $alert_obj       = $self;

    my $event_href      = {
        owner           => $controller->session('user'),
        readgroups      => $self->readgroups,
        modifygroups    => $self->modifygroups,
        status          => 'open',
        subject         => $self->subject,
        alerts          => [$self->alert_id ],
        sources          => $self->sources,
        'log'           => $log,
        controller      => $controller,
    };
    my $event_object    = Scot::Model::Event->new($event_href);
    my $event_id        = $mongo->create_document($event_object);

    $controller->notify_activemq({
        action  => "creation",
        type    => "event",
        id      => $event_id
    });

    return $self->promote_alert_to($event_object);

}

sub promote_event {
    my $self            = shift;
    my $controller      = $self->controller;
    my $mongo           = $controller->mongo;
    my $log             = $controller->app->log;
    my $event_id        = $self->event_id;

    my $incident_href   = {
        owner           => $controller->session('user'),
        readgroups      => $self->readgroups,
        modifygroups    => $self->modifygroups,
        status          => 'open',
        subject         => $self->subject,
        occurred        => $self->created,
        discovered      => $self->created,
        events          => [$self->event_id ],
        'log'           => $log,
        controller      => $controller,
    };
    my $incident_obj    = Scot::Model::Incident->new($incident_href);
    my $incident_id     = $mongo->create_document($incident_obj);

    return $self->promote_event_to($incident_obj);

}

=item C<promote_to>

 given an existing event or incident object
 promote the alert or event into that object

=cut

sub promote_to {
    my $self        = shift;
    my $target_obj  = shift;
    my $log         = $self->log;

    unless (defined $target_obj) {
        $log->error("Target object not defined!");
        return undef;
    }
    my %functions   = (
        'Scot::Model::Alertgroup'   => 'promote_alertgroup_to',
        'Scot::Model::Alert'        => 'promote_alert_to',
        'Scot::Model::Event'        => 'promote_event_to',
    );

    my $mytype      = ref($self);
    my $function    = $functions{$mytype};
    
    if ( defined $function ) {
        return $self->$function($target_obj);
    }
    $log->error("this objects type $mytype should not be promotable");
    return undef;
}

sub promote_alertgroup_to {
    my $self            = shift;
    my $event_object    = shift;
    my $controller      = $self->controller;
    my $mongo           = $controller->mongo;
    my $log             = $self->log;
    my $alertgroup_id   = $self->alertgroup_id;
    my $cursor          = $mongo->read_documents({
        collection  => "alerts",
        match_ref   => {alertgroup  => $alertgroup_id},
    });
    my $event_id        = $event_object->event_id;

    unless (defined $event_object) { 
        $log->error("Failed to provide an event object!");
        return undef;
    }
    if (ref($event_object) ne "Scot::Model::Event") {
        $log->error("Can only promote alerts to events");
        return undef;
    }
    unless (defined $event_object->controller) {
        $event_object->controller($controller);
    }

    my @promoted_alert_ids;
    my @rows;
    my $header;
    my $created;
    while ( my $alert_obj   = $cursor->next ) {
        $header  = $alert_obj->make_data_header;
        push @rows, $alert_obj->make_data_row;
        $created = $alert_obj->created;
        $alert_obj->add_event($event_id);
        $alert_obj->status('promoted');
        $alert_obj->add_historical_record({
            who     => $controller->session('user'),
            what    => "promoted to event $event_id",
            when    => $self->_timestamp,
        });
        if ( $mongo->update_document($alert_obj) ) {
            $log->debug("updated alert ".$alert_obj->alert_id);
            push @promoted_alert_ids, $alert_obj->alert_id;
            $controller->notify_activemq({
                action  => "update",
                type    => "alert",
                id      => $alert_obj->alert_id,
            });
        }
        else {
            $log->error("Failed to update alert ".$alert_obj->alert_id);
        }
    }
    my $entry_html  = qq|<table>|.$header.join('',@rows).qq|</table>|; 
    $event_object->add_entry({
        when    => $created,
        body    => $entry_html,
    });

    if ( $mongo->update_document($event_object) ) {
        $self->controller->notify_activemq({
            action  => "update",
            type    => "event",
            id      => $event_id,
        });
        $self->controller->update_activity_log({
            who     => $controller->session('user'),
            what    => "alert promotion", 
            when    => $self->_timestamp,
            data    => {
                alert_id    => \@promoted_alert_ids,
                event_id    => $event_id,
            }
        });
        # now update alertgroup obj
        # we could optimize here if needed by only updating the
        # changes, but unless performance of a promotion becomes
        # an issue, simpler and cleaner to just refresh the entire 
        # alertgroup obj
        $self->refresh_alertgroup($alertgroup_id);
    }
    else {
        $log->error("Failed to update Event $event_id with data entries!");
    }
    return $event_object;    
}

sub refresh_alertgroup {
    my $self    = shift;
    my $id      = shift;
    my $env     = $self->env;
    my $mongo   = $self->controller->mongo;
    my $alertgroup_obj  = $mongo->read_one_document({
        collection  => "alertgroups",
        match_re    => { alertgroup_id  => $id },
    });
    $alertgroup_obj->refresh_ag_data($env);
    $mongo->update_document($alertgroup_obj);
}


sub promote_alert_to {
    my $self            = shift;
    my $event_object    = shift;
    my $log             = $self->log;
    my $controller      = $self->controller;
    my $mongo           = $controller->mongo;
    my $event_id        = $event_object->event_id;

    $event_object->add_entry({
        owner   => $controller->session('user'),
        when    => $self->created,
        body    => $self->make_data_entry,
    });

    $self->add_event($event_id);
    $self->status('promoted');
    $self->add_historical_record({
        who     => $controller->session('user'),
        what    => "promoted to event $event_id",
        when    => $self->_timestamp,
    });

    if ( $mongo->update_document($self) ) {
        $log->debug("updated alert ".$self->alert_id);
        $self->controller->notify_activemq({
            action  => "update",
            type    => "alert",
            id      => $self->alert_id,
        });
        $self->controller->notify_activemq({
            action  => "update",
            type    => "alertgroup",
            id      => $self->alertgroup,
        });
    }
    else {
        $log->error("Failed to update alert ".$self->alert_id);
    }

    if ( $mongo->update_document($event_object) ) {
        $self->controller->notify_activemq({
            action  => "create",
            type    => "event",
            id      => $event_id,
        });
        $self->controller->update_activity_log({
            who     => $controller->session('user'),
            what    => "alert promotion", 
            when    => $self->_timestamp,
            data    => {
                alert_id    => $self->alert_id,
                event_id    => $event_id,
            }
        });
    }
    else {
        $log->error("Failed to update Event $event_id with data entries!");
    }
    return $event_object;    
}

sub promote_event_to {
    my $self            = shift;
    my $incident_obj    = shift;
    my $controller      = $self->controller;
    my $log             = $self->log;
    my $mongo           = $controller->mongo;
    my $incident_id     = $incident_obj->incident_id;

    $self->add_incident($incident_id);
    $self->status('promoted');
    $self->add_historical_record({
        who     => $controller->session('user'),
        what    => "promoted to incident $incident_id",
        when    => $self->_timestamp,
    });
    if ( $mongo->update_document($self) ) {
        $log->debug("updatd event ".$self->event_id);
        $self->controller->notify_activemq({
            action  => "update",
            type    => "event",
            id      => $self->event_id,
        });
    }
    else {
        $log->error("Failed to update event ".$self->event_id);
    }
    if ( $mongo->update_document($incident_obj) ) {
        $self->controller->notify_activemq({
            action  => "create",
            type    => "incident",
            id      => $incident_id,
        });
        $self->controller->update_activity_log({
            who     => $controller->session('user'),
            what    => "event promotion", 
            when    => $self->_timestamp,
            data    => {
                event_id       => $self->event_id,
                incident_id    => $incident_id,
            }
        });
    }
    else {
        $log->error("Failed to update Incident $incident_id with data entries!");
    }
    return $incident_obj;    
}

1;

