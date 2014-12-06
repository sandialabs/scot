package Scot::Controller::Reports;

use lib '../../../lib';
use v5.10;
use strict;
use warnings;

use Data::Dumper;
use Scot::Env;
use JSON;
use DateTime;

use Scot::Util::DateTimeUtils;
use base 'Mojolicious::Controller';


sub aei_by_time {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $start   = $self->parse_json_param("start_epoch"),
    my $end     = $self->parse_json_param("end_epoch"),
    my $secsaday    = 60*60*24;

    unless ( defined ($start) ) {
        $start  = $env->now - 60*$secsaday;
    }
    unless (defined ($end) ) {
        $end    = $env->now;
    }

    my $start_dt    = DateTime->from_epoch(epoch=>$start);
    my $end_dt      = DateTime->from_epoch(epoch=>$end);
    
    my @data = ();
    my %averages;

    foreach my $collection (qw(alertgroups events incidents)) {

        my $cursordt    = DateTime->new(
            year    => $start_dt->year,
            month   => $start_dt->month,
            day     => $start_dt->day,
            hour    => 0,
            minute  => 0,
            second  => 0,
        );
        my $cursorepoch = $cursordt->epoch;

        my $sum         = 0;
        my $days        = 0;
        my %temp        = ( key => $collection );


        while ( $cursorepoch + $secsaday <= $end ) {

            my $plusoneday  = $cursorepoch + $secsaday;
            my $match_href  = {
                created => { '$gte' => $cursorepoch, '$lte' => $plusoneday },
            };
            my $count  = $mongo->count_documents({
                collection  => $collection,
                match_ref   => $match_href,
            });
            my $mdy = DateTime->from_epoch(epoch=>$cursorepoch)->mdy;

            push @{$temp{values}}, [ $cursorepoch, $count, ];
            $sum                 += $count;
            $days                += 1;

            $cursorepoch = $plusoneday;
        }
        $averages{$collection} = $sum / $days;
        push @data, \%temp;
    }
        
    $self->render( json => \@data ) ;


}

sub events_entities_graph {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $redis   = $env->redis;
    my $start   = $self->param("start")+0 // 1000,
    my $end     = $self->param("end")+0 // 1010,
    my %data;
    my $cursor  = $mongo->read_documents({
        collection  => "events",
        match_ref   => { 
            event_id    => { '$gte' => $start, '$lte' => $end }
        }
    });

    my $entity_count    = 0;
    my $edge_count      = 0;
    my %entity_db       = ();

    while ( my $event = $cursor->next ) {
        my $event_id    = "event-".$event->event_id;
        push @{$data{nodes}}, {
            id      => $event_id,
            label   => "SCOT-".$event->event_id,
        };

        my @entities    = $redis->get_objects_entity_values($event);

        foreach my $entity (@entities) {
            unless ( $entity_db{$entity} ) {
                my $href    = {
                    id      => "entity-".$entity_count,
                    label   => $entity,
                };
                push @{$data{nodes}}, $href;
                $entity_db{$entity} = $href;
                $entity_count++;
            }
            push @{$data{links}}, {
                id      => "edge-".$edge_count,
                source  => $event_id,
                target  => $entity_db{$entity}{id},
            };
            $edge_count++;
        }
    }
    $self->render( json => \%data ) ;
}

sub event_entity_connection_graph {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $redis   = $env->redis;
    my $log     = $env->log;
    my $id      = $self->param("event_id")+0;
    my $depth   = $self->param("depth")+0 // 2;
    my @links   = ();

    my %seen    = ();
    $self->build_graph(\@links, \%seen, $id, "event", $depth);


    $self->render( json => \@links );
}


sub event_entity_connection_graph_old {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $redis   = $env->redis;
    my $log     = $env->log;
    my $id      = $self->param("event_id")+0;
    my $depth   = $self->param("depth")+0 // 2;
    my %graph   = ( nodes => [], links => [] );
    my %data    = ();

    $log->debug("Building event entity graph centered on $id to depth $depth");


    $self->get_graph_neighbors(\%data, \%graph, $id, "event", $depth);

    $log->debug("graph is ".Dumper(\%data));
    foreach my $type (qw(nodes links)) {
        $log->debug(" type is $type");
        foreach my $key (keys %{$data{$type}}) {
            push @{$graph{$type}}, $data{$type}{$key};
        }
    }
    
#    foreach my $node ( keys %{$data{nodes}} ) {
#        if ( defined $data{links}{$node} ) {
#            unless ($data{links}{$node} > 1) {
#                delete $data{nodes}{$node};
#                next;
#            }
#        }
#        push @{$graph{nodes}}, $data{nodes}{$node};
#    }
#
#    foreach my $edge ( keys %{$data{links}} ) {
#        my $src = $data{links}{$edge}->{source};
#        my $dst = $data{links}{$edge}->{target};
#        if ( defined $data{nodes}{$src} and defined $data{nodes}{$dst} ) {
#            push @{$graph{links}}, $data{links}{$edge}
#        }
#    }
    $self->render( json => \%graph );
}

sub build_graph {
    my $self    = shift;
    my $aref    = shift;
    my $href    = shift;
    my $node    = shift;
    my $type    = shift;
    my $depth   = shift;
    $depth--;
    if ( $depth < 0 ) { return; }

    if ( $type eq "event" ) {
         foreach my $entity ($self->get_entities($node)) {
            my $degree = $self->env->redis->get_entity_count($entity, "events");
            if ($degree > 10 or $degree <= 1) {
                next;
            }
            unless ( defined $href->{seen}->{$node.$entity} ) {
                push @{$aref}, { event => $node, entity => $entity };
                $href->{seen}->{$node.$entity}++;
                $href->{count}->{$entity}++;
            }
            $self->build_graph($aref, $href, $entity, "entity", $depth);
        }
    }
    else {
        foreach my $event ($self->get_events($node)) {
            unless ( $href->{seen}->{$event.$node} ) {
                push @{$aref}, { entity => $node, event => $event };
                $href->{seen}->{$event.$node}++;
                $href->{count}->{$node}++;
            }
            $self->build_graph($aref, $href, $event, "event", $depth);
        }
    }
}

sub get_graph_neighbors {
    my $self    = shift;
    my $data    = shift;    # hashref of traversal
    my $graph   = shift;    # building what d3 wants
    my $node    = shift;    # where we are
    my $type    = shift;    # what type it is
    my $depth   = shift;    # how far we have to go
    my $log     = $self->env->log;
    
    $depth--;
    if ( $depth < 0 ) {
        return;
    }
    my $node_name   = $node;   # default is an entity
    my $groupnum    = 2;
    if ( $type  eq "event" ) { 
        # special name for scot events
        $node_name  = "SCOT-".$node;
        $groupnum   = 1;
    }
    
    # add node to graph array and return the array index to that record
    unless ( defined $data->{nodes}->{$node_name} ) {
        $data->{nodes}->{$node_name} = 
            $self->add_to_graph_nodes($graph, $node_name, $groupnum);
    }


    if ( $type  eq "event" ) {
         foreach my $entity ($self->get_entities($node)) {
            my $degree = $self->env->redis->get_entity_count($entity, "events");
            if ($degree > 10 or $degree <= 1) {
                next;
            }
            unless ( defined $data->{nodes}->{$entity} ) {
                $data->{nodes}->{$entity} =
                    $self->add_to_graph_nodes($graph, $entity, 2); 
            }
            push @{$graph->{links}}, {
                source  => $data->{nodes}->{$node_name},
                target  => $data->{nodes}->{$entity},
                value   => 1,
            };
            $self->get_graph_neighbors($data, $graph, $entity, "entity", $depth);
        }
    }
    else {
        foreach my $event ($self->get_events($node)) {
            my $event_name  = "SCOT-".$event;
            unless ( defined $data->{nodes}->{$event_name} ) {
                $data->{nodes}->{$event_name} =
                    $self->add_to_graph_nodes($graph, $event_name, 1);
            }
            push @{$graph->{links}}, {
                source  => $data->{nodes}->{$node_name},
                target  => $data->{nodes}->{$event_name},
                value   => 1,
            };
            $self->get_graph_neighbors($data, $graph, $event, "event", $depth);
        }
    }
}

sub add_to_graph_nodes {
    my $self    = shift;
    my $graph   = shift;
    my $name    = shift;
    my $num     = shift;
    # add node to graph array and return the array index to that record
    push @{$graph->{nodes}}, {
        name    => $name,
        group   => $num,
    };
    return scalar(@{$graph->{nodes}})-1;
}


sub get_graph_neighbors_old {
    my $self    = shift;
    my $data    = shift;
    my $node    = shift;
    my $type    = shift;
    my $depth   = shift;
    my $cid     = shift;
    my $log     = $self->env->log;

    unless (defined $cid) {
        $cid    = $self->node_counter(0);
    }

    if ( $depth == 0 ) {
        return;
    }
    $depth--;

    my $node_name;
    if ( $type eq "event" ) {
        $node_name  = "SCOT-".$node;
    }
    else {
        $node_name  = $node;
    }
    $log->debug("Getting neighbors for $node_name");
    my $groupnum = 1;
       $groupnum = 2 if ($type eq "entity");

    $data->{nodes}->{$node_name} = {
        name   => $node_name,
        group  => $groupnum,
        cid     => $cid->(),
    };

    if ( $type  eq "event" ) {
         
         foreach my $entity ($self->get_entities($node)) {
            my $degree = $self->env->redis->get_entity_count($entity, "events");
            if ($degree > 10 or $degree <= 1) {
                next;
            }
            $data->{nodes}->{$entity} = {
                name   => $entity,
                group   => 1,
                cid     => $cid->(),
            };
            my $linkname = $node_name . '-' . $entity;

            if ( defined $data->{links}->{$linkname} ) {
                $data->{links}->{$linkname}->{value}++;
            }
            else {
                $data->{links}->{$linkname} = {
                    source  => $data->{nodes}->{$node_name}->{cid},
                    target  => $data->{nodes}->{$entity}->{cid},
                    value   => 1,
                };
            }
            $self->get_graph_neighbors($data, $entity, "entity", $depth, $cid);
        }
    }
    else {
        
        foreach my $event ($self->get_events($node)) {
            my $event_name  = "SCOT-".$event;
            $data->{nodes}->{$event_name} = {
                name      => $event_name,
                group     => 2,
                cid         => $cid->(),
            };
            my $linkname   = $event_name . '-' . $node_name;
            if ( defined $data->{links}->{$linkname} ) {
                $data->{links}->{$linkname}->{value}++;
            }
            else {
                $data->{links}->{$linkname} = {
                    source  => $data->{nodes}->{$event_name}->{cid},
                    target  => $data->{nodes}->{$node_name}->{cid},
                    value  => 1,
                };
            }
            $self->get_graph_neighbors($data, $event, "event", $depth, $cid);
        }
    }
}

sub node_counter {
    my $self    = shift;
    my $start   = shift // 0;
    return sub { $start++ };
}

sub neighbor_graph {
    my $self        = shift;
    my $event_id    = $self->param('event_id') + 0;
    my $depth       = $self->param('depth') + 0 // 2;
    
    $self->render(
        event_id    => $event_id,
        depth       => $depth,
    );
}

sub get_entities {
    my $self    = shift;
    my $eventid = shift;
    my $redis   = $self->env->redis;
    return $redis->get_event_entities($eventid);
}

sub get_events {
    my $self    = shift;
    my $entity  = shift;
    my $redis   = $self->env->redis;
    return $redis->get_entitys_events($entity);
}
        
sub build_tree {
    my $self    = shift;
    my $href    = shift;
    my $child   = shift;
    my $type    = shift;

    if ( $type eq "event" ) {

        $href->{name} = $child;
    }
}

sub get_avail_reports {
    my $self    = shift;
    my @reports = (
        { name  => "Alert Quantities by Month", 
          report => "aqbm" },
        { name  => "Alert Response Times by Month",
          report  => "artbm" },
#        { name  => "Compare Alerts by day of the week",
#          report  => "cadow" },
    );
    $self->render(json => \@reports);
}

sub get_report {
    my $self    = shift;
    my $json    = $self->get_json;
    my $report  = $json->{report};
    my $start   = $json->{start_epoch};
    my $end     = $json->{end_epoch};

    if ( $report eq "aqbm" ) {
        $self->alert_quantities_monthly($start, $end);
    }
    elsif ( $report eq "artbm" ) {
        $self->alert_response_times($start, $end);
    }
    elsif ( $report eq "cadow" ) {
        $self->compare_alerts_dow($start, $end);
    }
    else {
        $self->env->log->error("Unknown report type! $report");
        $self->render( json => {error => "unknown report type $report"} );
    }
}

sub alert_quantities_monthly {
    my $self    = shift;
    my $start   = shift;
    my $end     = shift;
    my $counter = 0;
    my $mongo   = $self->env->mongo;
    my $cursor  = $mongo->read_documents({
        collection  => "alertgroups",
        match_ref   => {
            '$and'  => [
                { when => { '$gte'  => $start} },
                { when => { '$lte'  => $end} },
            ],
        },
    });
    my $total   = $cursor->count;
    my %results = ();
    my $flag    = undef;

    while ( my $alert   = $cursor->next_raw ) {
        my $dt  = DateTime->from_epoch( epoch => $alert->{when});
        my $m   = $dt->month;
        my $y   = $dt->year;
        $results{$y.'-'.$m}++;
    }

    my %ts  = (
        x   => [ 'x' ],
        alert_count => [ 'alerts' ]
    );
    foreach my $ym (sort keys %results) {
        push @{$ts{x}}, $ym.'-1';
        push @{$ts{alert_count}}, $results{$ym};
    }

    $self->env->log->debug("Returning ".scalar(@{$ts{alert_count}})." items");
    
    $self->render( json => {
        x       => 'x',
        columns => [
            $ts{x},
            $ts{alert_count},
        ],
    });
}

sub alert_response_times {
    my $self    = shift;
    my $start   = shift;
    my $end     = shift;
    my $mongo   = $self->env->mongo;
    my $cursor  = $mongo->read_documents({
        collection  => "alertgroups",
        match_ref   => {
            '$and'  => [
                { when => { '$gte'  => $start} },
                { when => { '$lte'  => $end} },
            ],
        },
        sort_ref    => { alertgroup_id => 1 },
    });

    my %results;
    while ( my $alertgroup = $cursor->next ) {
        my $when    = $alertgroup->when;
        my $dt      = DateTime->from_epoch( epoch => $when);
        my $month   = $dt->month;
        my $year    = $dt->year;
        my $hour    = $dt->hour;
        my $day     = $dt->day_of_week;
        if ( $day > 0 and $day < 6 ) {
            if ( $hour < 18 and $hour > 7 ) {
                my $first_view = $self->get_earliest($alertgroup->viewed_by);
                if ( $first_view ) {
                    my $delta = $first_view - $when;
                    printf " %d seconds\n", $delta;
                    if ( $delta > 0 ) {
                        $results{$year}{$month}{total_time} += $delta;
                        $results{$year}{$month}{count}++;
                    }
                }
            }
            # print " After Hours...\n";
        }
        else {
            # print " Skipping the weekend...\n";
        }
    }

    my @x   = (qw(x));
    my @rt  = ('Response (seconds)');

    foreach my $y ( sort {$a<=>$b} keys %results ) {
        foreach my $m ( sort {$a<=>$b} keys %{$results{$y}} ) {
            my $count   = $results{$y}{$m}{count};
            my $time    = $results{$y}{$m}{total_time};
            my $avg     = $time / $count;
            push @x, "$y-$m-1";
            push @rt, sprintf("%4.1f", $avg);
        }
    }
    $self->render( json => {
        x       => 'x',
        columns => [
            \@x,
            \@rt,
        ],
    });
}

sub get_earliest {
    my $self    = shift;
    my $href    = shift;
    my @times   =   sort { $a <=> $b}
                    grep { $_ == $_ }
                    map  { $href->{$_}->{when} }
                    keys %{$href};
    foreach my $t (@times) {
        return $t if ( $t != 0 );
    }
    return undef;
}


1;




