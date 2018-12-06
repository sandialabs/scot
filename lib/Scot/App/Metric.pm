package Scot::App::Metric;

use lib '../../../lib';
use lib '/opt/scot/lib';
use strict;
use warnings;
# use v5.18;

use Data::Dumper;
use DateTime;
use DateTime::Duration;
use Try::Tiny;
use Scot::Env;
use Log::Log4perl::Level;
use Statistics::Descriptive;
use Data::Dumper;
use MongoDB::Code;
use Moose;
extends 'Scot::App';

sub march {
    my $self    = shift;
    my $reports = shift; # match the sub name
    my $curdt   = shift;
    my $stopdt  = shift;
    my $log     = $self->env->log;

    while ( DateTime->compare($curdt, $stopdt) > 0 ) {
        my ($sdt,$edt) = $self->get_daily_dts($curdt);
        say "Examining ".$curdt->ymd." ".$sdt->hms." to ".$edt->hms;
        say "    ".$sdt->epoch." to ".$edt->epoch;

        my $t;
        foreach my $report (@$reports) {
            say "    $report calculation";
            $t = $self->env->get_timer($report);
            $self->$report($sdt,$edt);
            say "        ".&$t." elapsed seconds";
        }

        $curdt->subtract( days => 1 );
    }
}
    

sub get_daily_dts {
    my $self    = shift;
    my $dt      = shift;
    my $start   = $dt->clone();
    my $end     = $dt->clone();

    $start->set( hour => 0,  minute => 0,  second => 0 );
    $end->set  ( hour => 23, minute => 59, second => 59);

    return $start, $end;
}

sub get_hourly_epochs {
    my $self    = shift;
    my $dt      = shift;
    my $start   = $dt->clone();
    my $end     = $dt->clone();

    $start->set( minute => 0,  second => 0 );
    $end->set  ( minute => 59, second => 59);

    return $start->epoch, $end->epoch;
}

sub build_doc {
    my $self    = shift;
    my $nowdt   = shift;
    my $name    = shift;
    my $count   = shift;
    return {
        year    => $nowdt->year,
        month   => $nowdt->month,
        day     => $nowdt->day,
        dow     => $nowdt->dow,
        quarter => $nowdt->quarter,
        hour    => $nowdt->hour,
        metric  => $name,
        value   => $count,
    };
}

sub build_agg_cmd {
    my $self    = shift;
    my $metric  = shift;
    my $startdt = shift;
    my $enddt   = shift;
    my @cmd     = (
        {
            '$match'  => {
                created => {
                    '$lte'  => $enddt->epoch,
                    '$gte'  => $startdt->epoch,
                }
            }
        },
        {
           '$project'   => {
                dt  => {
                    '$add'  => [
                        DateTime->from_epoch( epoch => 0 ),
                        { '$multiply' => [ '$created', 1000 ] }
                    ]
                },
            }
        },
        {
            '$group'    => {
                _id => {
                    metric  => $metric,
                    year    => { '$year'    => '$dt' },
                    month   => { '$month'   => '$dt' },
                    day     => { '$dayOfMonth'  => '$dt' },
                    hour    => { '$hour'    => '$dt' },
                    dowx    => { '$dayOfWeek'   => '$dt' },
                },
                count   => { '$sum' => 1 },
            }
        },
        {
            '$sort' => {
                "_id.month" => 1,
                "_id.day" => 1,
                "_id.hour" => 1,
            }
        }
    );
    return \@cmd;
}

=item B<pyramid>

between the supplied start and end datetimes
count the number of alerts events and incidents created
by the hour.  results in documents like:
    {
        'dow' => 1,
        'month' => 4,
        'year' => 2016,
        'day' => 18,
        'count' => 1,
        'hour' => 21,
        'metric' => 'incident created'
    };

being upserted into the Stat collection
upserting will overwrite existing values that may have been created
as the API/Flair/Stretch/ modules do stuff.  Should be in agreement
anyway, but you are warned.

=cut

sub pyramid {
    my $self    = shift;
    my $startdt = shift;
    my $enddt   = shift;
    my $mongo   = $self->env->mongo;
    my $statcol = $mongo->collection('Stat');

    foreach my $type (qw(alert event incident)) {
        my $aggcmd  = $self->build_agg_cmd("$type created",$startdt, $enddt);
        my $col = $mongo->collection(ucfirst($type));
        my $cur = $col->get_aggregate_cursor($aggcmd);
        while ( my $href = $cur->next ) {
            # need to translate dowx (mongo 1=Sunday to perl dow 1=Monday)
            my $res = delete $href->{_id};
            my $dowx = delete $res->{dowx};
            $res->{dow} = 7            if ( $dowx == 1 );
            $res->{dow} = $dowx - 1    if ( $dowx > 1 );
            $res->{value} = $href->{count};
            $statcol->upsert_metric($res);
        }
    }
}



=item B<alert_response_time>

This calculates the sum response times (alert created until first view)
like pyramid above, this upserts the response times, so although it
overwrites data, it should be safe to run multiple times.  in fact it 
probably should be re-run from time to time to catch changes to the alert 
promotion data

=cut
        
sub alert_response_time_agg {
    my $self    = shift;
    my $startdt = shift;
    my $enddt   = shift;
    my $mongo   = $self->env->mongo;
    my $statcol = $mongo->collection('Stat');

    my $aggcmd  = $self->build_response_time_aggregation($startdt,$enddt);
    my $aggcol  = $mongo->collection('Alert');
    say "Agg Cmd is ".Dumper($aggcmd);
    my $cursor  = $aggcol->get_aggregate_cursor($aggcmd);

    while ( my $href = $cursor->next ) {
            if ( $href->{value} == 0 ) {
                say "0";
                say Dumper($href);
            }
            else {
                say Dumper($href);
            }
            # need to translate dowx (mongo 1=Sunday to perl dow 1=Monday)
            my $res = delete $href->{_id};
            my $dowx = delete $res->{dowx};
            # first metric sum(response times)
            $res->{value} = $href->{value} // 0; 
            $res->{metric} = "Sum of alert response times";
            $statcol->upsert_metric($res);
            # second metric count of the alerts summed above
            $res->{value} = $href->{alerts} // 0;
            $res->{metric} = "Total of viewed alerts";
            $statcol->upsert_metric($res);
            # now a later query to Stat collection can rapidly calcuate
            # averages based on the rollup selected.
    }
}

sub alert_response_time {
    my $self    = shift;
    my $startdt = shift;
    my $enddt   = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    $log->debug("STARTING Alert Response Time");

    my $statcol = $mongo->collection('Stat');
    my $agcol   = $mongo->collection('Alertgroup');
    my $ecol    = $mongo->collection('Event');

    my $agmatch = {
        '$or' => [
            {view_count  => { '$gt'  => 0 }},
            {views       => { '$gt'  => 0 }},
        ],
        created     => {
            '$lte'  => $enddt->epoch,
            '$gte'  => $startdt->epoch,
        },
    };
    my $agcursor    = $agcol->find($agmatch);
    $agcursor->immortal(1);
    $agcursor->sort({id => -1}); # work backwards

    # $log->debug("Got ".$agcursor->count." alertgroups");

    my %all         = ();
    my %promoted    = ();
    my %incident    = ();
    my $sum_all        = "Sum of all Alertgroup Response Times (seconds)";
    my $count_all      = "Count of all Alertgroup Response Times";
    my $sum_pro        = "Sum of promoted Alertgroup Response Times (seconds)";
    my $count_pro      = "Count of promoted Alertgroup Response Times";
    my $sum_inc        = "Sum of incident Alertgroup Response Times (seconds)";
    my $count_inc      = "Count of incident Alertgroup Response Times";

    while ( my $alertgroup = $agcursor->next ) {
        my $id          = $alertgroup->id;
        my $debugstr    = "Alertgroup $id: ";
        my $firstview   = $alertgroup->firstview;
        if (! defined $firstview) {
            $log->error("Alertgroup $id firstview not defined!");
            next;
        }
        if ($firstview < 0) {
            $log->error("Alertgroup $id: Problem with firstview value!");
            next;
        }
        my $created = $alertgroup->created;
        if (! defined $created) {
            $log->error("Alertgroup $id: problem with created value!");
            next;
        }
        my $response    = $firstview - $created;
        if ( $response <= 0 ) {
            $log->error("Alertgroup $id: invalid response time!");
            $log->error("Alertgroup $id: firstview: $firstview");
            $log->error("Alertgroup $id: created  : $created");
            next;
        }
        my $dt      = DateTime->from_epoch(epoch => $created);

        $all{$dt->year}{$dt->month}{$dt->day}{$dt->hour}{sum} += $response;
        $all{$dt->year}{$dt->month}{$dt->day}{$dt->hour}{count}++;

        $debugstr .= "response = $response ";

        my $status  = $alertgroup->status;
        $debugstr .= "status = $status ";
        if ($status eq "promoted") {
            $promoted{$dt->year}{$dt->month}
                     {$dt->day}{$dt->hour}{sum} += $response;
            $promoted{$dt->year}{$dt->month}
                     {$dt->day}{$dt->hour}{count}++;
            # check if it made it all the way to an incident
            my $event   = $ecol->find_iid($alertgroup->promotion_id);
            if ( ! defined $event ) {
                $log->warn("Alertgroup $id: problem with promotion_id");
                next;
            }
            my $event_status = $event->status;
            if ( ! defined $event_status ) {
                $log->warn("Event ".$event->id.": problem with status");
                next;
            }
            if ( $event_status eq "promoted" ) {
                $incident{$dt->year}{$dt->month}
                        {$dt->day}{$dt->hour}{sum} += $response;
                $incident{$dt->year}{$dt->month}
                        {$dt->day}{$dt->hour}{count}++;
            }
        }
        $log->debug($debugstr);

    }

    foreach my $y (sort keys %all) {
        foreach my $m (sort keys %{$all{$y}} ) {
            foreach my $d (sort keys %{$all{$y}{$m}}) {
                foreach my $h (sort keys %{$all{$y}{$m}{$d}}) {
                    my $allhref = $all{$y}{$m}{$d}{$h};
                    my $prohref = $promoted{$y}{$m}{$d}{$h};
                    my $inchref = $incident{$y}{$m}{$d}{$h};

                    my @metrics = (
                        {
                            year    => $y + 0,
                            month   => $m + 0,
                            day     => $d + 0,
                            hour    => $h + 0,
                            metric  => $sum_all,
                            value   => $allhref->{sum} // 0,
                        },
                        {
                            year    => $y + 0,
                            month   => $m + 0,
                            day     => $d + 0,
                            hour    => $h + 0,
                            metric  => $count_all,
                            value   => $allhref->{count} // 0,
                        },
                        {
                            year    => $y + 0,
                            month   => $m + 0,
                            day     => $d + 0,
                            hour    => $h + 0,
                            metric  => $sum_pro,
                            value   => $prohref->{sum} // 0,
                        },
                        {
                            year    => $y + 0,
                            month   => $m + 0,
                            day     => $d + 0,
                            hour    => $h + 0,
                            metric  => $count_pro,
                            value   => $prohref->{count} // 0,
                        },
                        {
                            year    => $y + 0,
                            month   => $m + 0,
                            day     => $d + 0,
                            hour    => $h + 0,
                            metric  => $sum_inc,
                            value   => $inchref->{sum} // 0,
                        },
                        {
                            year    => $y + 0,
                            month   => $m + 0,
                            day     => $d + 0,
                            hour    => $h + 0,
                            metric  => $count_inc,
                            value   => $inchref->{count} // 0,
                        },
                    );
                    foreach my $metric (@metrics) {
                        say Dumper($metric);
                        # $log->debug("writing metric ",{filter=>\&Dumper,value=>$metric});
                        $statcol->upsert_metric($metric);
                    }
                }
            }
        }
    }
}



sub build_response_time_aggregation {
    my $self    = shift;
    my $startdt = shift;
    my $enddt   = shift;
    my @cmd     = (
        {
            '$match'  => {
#   think view_count is problem, doesn't exist in individal alerts
#                view_count => {'$gt'    => 0},
                created => {
                    '$lte'  => $enddt->epoch,
                    '$gte'  => $startdt->epoch,
                }
            }
        },
        {
            '$lookup'   => {
                from        => 'alertgroup',
                localField  => 'alertgroup',
                foreignField=> 'id',
                as          => "agdoc",
            }
        },
        {
           '$project'   => {
                dt  => {
                    '$add'  => [
                        DateTime->from_epoch( epoch => 0 ),
                        { '$multiply' => [ '$created', 1000 ] }
                    ]
                },
                response => {
                    '$cond' => {
                        if  => {
                            '$eq'   => [
                                { '$arrayElemAt'=>['$adoc.firstview',0] },
                                -1
                            ]
                        },
                        then    => 0,
                        else    => {
                            '$subtract' => [
                                { '$arrayElemAt'=>['$adoc.firstview',0] },
                                '$created',
                            ],
                        },
                    },
                },
                count   => {
                    '$cond' => {
                        if  => {
                            '$eq'   => [
                                { '$arrayElemAt'=>['$adoc.firstview',0] },
                                -1
                            ]
                        },
                        then    => 0,
                        else    => 1,
                    },
                },
            }
        },
        {
            '$group'    => {
                _id => {
                    metric  => "alert response time",
                    year    => { '$year'    => '$dt' },
                    month   => { '$month'   => '$dt' },
                    day     => { '$dayOfMonth' => '$dt' },
                    hour    => { '$hour'    => '$dt' },
                },
                value   => { '$sum' => '$response' },
                alerts  => { '$sum' => '$count' },
            }
        },
        {
            '$sort' => {
                '_id.month' => 1,
                '_id.day'   => 1,
                '_id.hour'  => 1,
            }
        }
    );
    return wantarray ? @cmd : \@cmd;
}

# alerttype metric help determine usefulness of an alerttype
# {
#     alert_subject: 
#     year:
#     month:
#     count:
#     open:
#     close:
#     promoted:
#     incident: # number that yielded an incident # might need to do it post
#     avg response time:
# }

sub alerttype_metrics {
    my $self    = shift;
    my $startdt = shift;
    my $enddt   = shift;
    my $mongo   = $self->env->mongo;
    my $statcol = $mongo->collection('Stat');
    my $ag_col  = $mongo->collection('Alertgroup');
    my $a_col   = $mongo->collection('Alert');
    my $e_col   = $mongo->collection('Event');
    my $s_col   = $mongo->collection('Atmetric');
    my $log     = $self->env->log;

    $log->debug("Getting Alertgroups");
    my $group_cursor    = $ag_col->find({
        created => {
            '$lte'  => $enddt->epoch,
            '$gte'  => $startdt->epoch,
        }
    });
    $group_cursor->immortal(1);

    my %r   = ();
    while (my $alertgroup = $group_cursor->next ) {
        my $created = $alertgroup->created;
        my $subject = $alertgroup->subject;
        my ($year, $month, $day,
            $dow, $quarter, $hour ) = $self->get_dt_breakout($created);
        $log->debug("   Getting alerts in alertgroup ".$alertgroup->id);
        my $alert_cursor = $a_col->find({alertgroup => $alertgroup->id});

        while ( my $alert = $alert_cursor->next ) {
            my $status  = $alert->status;

            $r{$subject}{$year}{$month}{$day}{$hour}{count}++;
            $r{$subject}{$year}{$month}{$day}{$hour}{$status}++;

            if ($alertgroup->firstview != -1) {
                my $rt = ($alertgroup->firstview - $alert->created);
                push @{$r{$subject}{$year}{$month}{$day}{$hour}{rt}}, $rt;
            }
            if ($alert->promotion_id != 0) {
               #  $r{$subject}{$year}{$month}{$day}{$hour}{promoted}++;
                my $event   = $e_col->find_iid($alert->promotion_id);
                if ( defined $event ) {
                    $log->debug("got event, checking promotion status");
                    if ( $event->status eq "promoted" ) {
                        $log->debug("Promoted!");
                        $r{$subject}{$year}{$month}{$day}{$hour}{incident} ++;
                    }
                }
            }
        }
    }
    foreach my $s (keys %r) {
        foreach my $y (sort keys %{$r{$s}} ) {
            foreach my $m (sort keys %{$r{$s}{$y}} ) {
                foreach my $d (sort keys %{$r{$s}{$y}{$m}} ) {
                    foreach my $h (sort keys %{$r{$s}{$y}{$m}{$d}} ) {
                        my $p   = $r{$s}{$y}{$m}{$d}{$h};
                        $log->debug("results are ",{filter=>\&Dumper, value=>$p});
                        my $stats = $self->get_stats($p->{rt});
                        my $row = {
                            alerttype   => $s,
                            year        => $y,
                            month       => $m,
                            day         => $d,
                            hour        => $h,
                            count       => $p->{count}//0,
                            open        => $p->{open}//0,
                            closed      => $p->{closed}//0,
                            promoted    => $p->{promoted}// 0,
                            rt_sum      => $stats->{sum} // 0,
                            rt_count    => $stats->{count} // 0,
                            incident    => $p->{incident} // 0,
                        };
                        # now stuff into AtMetric
                        $log->debug("upserting atmetric...");
                        $s_col->upsert_metric($row);
                    }
                }
            }
        }
    }
}

sub get_stats {
    my $self    = shift;
    my $aref    = shift;
    my $stat    = Statistics::Descriptive::Sparse->new();
    $stat->add_data(@$aref);
    return {
#        avg => $stat->mean,
        sum => $stat->sum,
        count => $stat->count,
#        min => $stat->min,
#        max => $stat->max,
#        sd  => $stat->standard_deviation,
    };
}

sub get_dt_breakout {
    my $self    = shift;
    my $epoch   = shift;
    my $dt      = DateTime->from_epoch(epoch => $epoch);
    return $dt->year, $dt->month, $dt->day, $dt->dow, $dt->quarter, $dt->hour;
}

# this would be nice if I could actually get this shit to work
sub build_alerttype_agg_cmd {
    my $self    = shift;
    my $startdt = shift;
    my $enddt   = shift;
    my @cmd     = (
        {
            '$match'  => {
                created => {
                    '$lte'  => $enddt->epoch,
                    '$gte'  => $startdt->epoch,
                }
            }
        },
        {
            '$lookup'   => {
                from        => 'alertgroup',
                localField  => 'alertgroup',
                foreignField=> 'id',
                as          => "agdoc",
            }
        },
        {
           '$project'   => {
                id  => 1,
                'agdoc.subject'  => 1,
                status  => 1,
                dt  => {
                    '$add'  => [
                        DateTime->from_epoch( epoch => 0 ),
                        { '$multiply' => [ '$created', 1000 ] }
                    ]
                },
                response => {
                    '$cond' => {
                        if  => {
                            '$eq'   => [
                                { '$arrayElemAt'=>['$agdoc.firstview',0] },
                                -1
                            ]
                        },
                        then    => undef,
                        else    => {
                            '$subtract' => [
                                { '$arrayElemAt'=>['$agdoc.firstview',0] },
                                '$created',
                            ],
                        },
                    },
                },
            }
        },
        {
            '$group'    => {
                _id => {
                    subject => '$agdoc.subject',
                    year    => { '$year'    => '$dt' },
                    month   => { '$month'   => '$dt' },
                    day     => { '$dayOfMonth' => '$dt' },
                },
                count   => { '$sum' => 1 },
                open    => {
                    '$sum'  => {
                        '$cond' => {
                            if  => { '$eq'  => [ '$status', "open" ] },
                            then => 1,
                            else => 0,
                        }
                    }
                },
                closed    => {
                    '$sum'  => {
                        '$cond' => {
                            if  => { '$eq'  => [ '$status', "closed" ] },
                            then => 1,
                            else => 0,
                        }
                    }
                },
                promoted    => {
                    '$sum'  => {
                        '$cond' => {
                            if  => { '$eq'  => [ '$status', "promoted" ] },
                            then => 1,
                            else => 0,
                        }
                    }
                },
                response_time_min   => { '$min'   =>  '$response' },
                response_time_avg   => { '$avg'   => '$response' },
                response_time_max   => { '$max'   => '$response' },
                response_time_sd    => { '$stdDevPop' => '$response' },
            },
        },
        {
            '$sort' => {
                '_id.subject'   => 1,
                '_id.year'      => 1,
                '_id.month'     => 1,
            }
        }
    );
    return wantarray ? @cmd : \@cmd;
}

##
## create promoted count records for stat
## (should only be used to "catch up"  newest SCOT's should 
## create stats for promotion as it goes.
##

sub promoted_count {
    my $self    = shift;
    my $startdt = shift;
    my $enddt   = shift;
    my $log         = $self->env->log;
    my $mongo       = $self->env->mongo;
    my $statcol     = $mongo->collection('Stat');
    my $alertcol    = $mongo->collection('Alert');
    my $eventcol    = $mongo->collection('Event');

    my $event_cursor    = $eventcol->find({
        created => {
            '$lte'  => $enddt->epoch,
            '$gte'  => $startdt->epoch,
        }
    });
    $event_cursor->immortal(1);

    my %r = ();

    while ( my $event = $event_cursor->next ) {
        my $promoted_from   = $event->promoted_from;
        my $promoted_to     = $event->promotion_id;
        my ($y, $m, $d, $dow, $quarter, $h) = $self->get_dt_breakout($event->created);

        if (defined $promoted_to ) {
            if ( $promoted_to != 0 ) {
                $r{$y}{$m}{$d}{$h}{'promoted event count'}++;
            }
        }

        if (defined $promoted_from) {
            if ( scalar(@{$promoted_from}) > 0 ) {
                foreach my $id (@{$promoted_from}) {
                    my $alert = $alertcol->find_iid($id);
                    if (defined $alert) {
                        my ($ya, $ma, $da, $dowa, $qa, $ha) = $self->get_dt_breakout($alert->created);
                        $r{$ya}{$ma}{$da}{$ha}{'promoted alert count'}++;
                    }
                    else {
                        $log->warn("Alert $id not found");
                    }
                }
            }
            else {
                $log->warn("No alerts in promoted_from array");
            }
        }
        else {
            $log->warn("No promoted_from array");
        }
    }
    foreach my $y (keys %r) {
        foreach my $m (keys %{$r{$y}}) {
            foreach my $d (keys %{$r{$y}{$m}}) {
                foreach my $h (keys %{$r{$y}{$m}{$d}}) {
                    foreach my $metric (keys %{$r{$y}{$m}{$d}{$h}}) {
                        my $value  = $r{$y}{$m}{$d}{$h}{$metric} // 0;
                        my $row = {
                            year    => $y,
                            month   => $m,
                            day     => $d,
                            hour    => $h,
                            metric  => $metric,
                            value   => $value,
                        };
                        $log->debug("upserting promotion $y/$m/$d $h: $metric = $value");
                        $statcol->upsert_metric($row);
                    }
                }
            }
        }
    }
}

sub alert_open_closed {
    my $self    = shift;
    my $startdt = shift;
    my $enddt   = shift;
    my $log         = $self->env->log;
    my $mongo       = $self->env->mongo;
    my $statcol     = $mongo->collection('Stat');
    my $alertcol    = $mongo->collection('Alert');

    my $alert_cursor    = $alertcol->find({
        created => {
            '$lte'  => $enddt->epoch,
            '$gte'  => $startdt->epoch,
        },
        status  => {
            '$in'   => [ 'open', 'closed' ],
        },
    });

    my %r   = ();
    while ( my $alert = $alert_cursor->next ) {
        my $status  = $alert->status;
        my ($y, $m, $d, $dow, $quarter, $h) = $self->get_dt_breakout($alert->created);
        $r{$y}{$m}{$d}{$h}{$status." alert count"}++;
    }
    foreach my $y (keys %r) {
        foreach my $m (keys %{$r{$y}}) {
            foreach my $d (keys %{$r{$y}{$m}}) {
                foreach my $h (keys %{$r{$y}{$m}{$d}}) {
                    foreach my $metric (keys %{$r{$y}{$m}{$d}{$h}}) {
                        my $value  = $r{$y}{$m}{$d}{$h}{$metric} // 0;
                        my $row = {
                            year    => $y,
                            month   => $m,
                            day     => $d,
                            hour    => $h,
                            metric  => $metric,
                            value   => $value,
                        };
                        $log->debug("upserting promotion $y/$m/$d $h: $metric = $value");
                        $statcol->upsert_metric($row);
                    }
                }
            }
        }
    }
}



    
1;
