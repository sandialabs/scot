package Scot::Domain::Event;

use Moose;
use experimental 'signatures';
use strict;
use warnings;
no warnings qw(experimental::signatures);
use Data::Dumper;
use Tie::IxHash;

extends 'Scot::Domain';

sub create_from_post ($self, $request) {
    my $log     = $self->env->log;

    $log->trace(__PACKAGE__." create : ", {filter => \&Dumper, value => $request});

    my @results = $self->create_event($request);
    return $self->process_create_results(\@results);
}

sub create_event ($self, $request) {
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my @results = ();
    my $owner   = $request->{user} // 'unknown';
    my $json    = $request->{data}->{json};
    my @tags    = $self->get_array_from_request_data($json, 'tags');
    my @sources = $self->get_array_from_request_data($json, 'sources');
    my ($alerts_aref,
        $alert_promotion_entry_data) = $self->process_attached_alerts($json);
    my $included_entry = delete $json->{entry};
    my $permissions = $self->validate_permissions($json, undef); # no target

    my @entries = ();
    push @entries, $alert_promotion_entry_data if (defined $alert_promotion_entry_data);
    push @entries, $included_entry if (defined $included_entry);

    my $event_data  = {
        owner   => $owner,
        groups  => $permissions,
        tlp     => $json->{tlp} // 'unset',
        subject => $json->{subject} // 'unknown',
        promoted_from   => $alerts_aref,
    };

    my $event       = $mongo->collection('Event')->create($event_data);
    if ( ! defined $event ) {
        $log->error("Error Creating Event from ",{filter=>\&Dumper, value=>$request});
        push @results, { error => 'failed to create event' };
        return wantarray ? @results : \@results;
    }
    push @results, { action => 'created', 
                     user => $request->{user}, 
                     target => 'event', 
                     id => $event->id };

    push @results, $self->add_tag_source_to_thing($event, 'tag', \@tags) if (scalar(@tags));
    push @results, $self->add_tag_source_to_thing($event, 'source', \@sources) if (scalar(@sources));
    return wantarray ? @results : \@results;
}

sub process_create_results ($self, $results) {
    my $env = $self->env;
    my $log = $env->log;
    my $renderdata  = { };

    foreach my $result (@$results) {
        my $error   = $result->{error};
        if ( defined $error ) {
            die $error;
        }
        my $mq_message = [{
            queues  => [ "/topic/scot" ],
            message => {
                action  => $result->{action},
                data    => {
                    who => $result->{user},
                    type => $result->{target},
                    id  => $result->{id},
                }
            }
        }];
        $self->send_mq($mq_message);
        if ( $result->{target} eq 'event' ) {
            # should only be one
            $renderdata = { code => 200, json => $result };
        }
    }
    return $renderdata;
}

sub process_attached_alert ($self, $json) {
    my $mongo   = $self->env->mongo;
    my $alerts  = delete $json->{from_alerts};

    # we may not have been passed alerts because not a promotion
    if (! defined $alerts ) {
        return undef, undef;
    }

    my $alert_cursor    = $mongo->collection('Alert')->find({
        id  => {
            '$in'   => $alerts
        }
    });

    my %columns = ();
    tie %columns, 'Tie::IxHash';
    my @rows    = ();

    while (my $alert = $alert_cursor->next) {
        my $alert_columns = $alert->columns;
        map { $columns{$_}++ } @$alert_columns; # keep a list of all columns seen
        my $alert_row = $alert->data;        
        push @rows, $alert_row;
    }
    my $entry_body = $self->build_alert_entry_body(\%columns, \@rows);

    my $entry_data  = {
        target  => {},  # to be filled in once entry is created
        groups  => [],  # ditto
        summary => 0,
        body    => $entry_body,
    };
    return $alerts, $entry_data;
}

sub build_alert_entry_body ($self, $col_hash, $row_aref) {
    my $entry_body  = '<h4>Promoted Alerts</h4>'.
                      '  <table class="alert_in_entry">';

    my $header  = '  <tr>';
    foreach my $col (keys %$col_hash) {    # ixhash will give us in order inserted
        $header .= '<th>'.$col.'</th>';
    }
    $header .= '</tr>';
    $entry_body .= $header;

    foreach my $row (@$row_aref) {
        $entry_body .= '<tr>';
        foreach my $col (keys %$col_hash) {
            $entry_body .= '<td>'.$row->{$col}.'</td>';
        }
        $entry_body .= '</tr>';
    }
    $entry_body .= '</table>';
    return $entry_body;
}

1;
