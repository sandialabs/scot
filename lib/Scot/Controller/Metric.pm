package Scot::Controller::Metric;

use Data::Dumper;
use Try::Tiny;
use DateTime;
use DateTime::Format::Strptime;
use Mojo::JSON qw(decode_json encode_json);
use Statistics::Descriptive;
use File::Slurp;

use strict;
use warnings;
use base 'Mojolicious::Controller';

sub get {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $thing   = $self->stash('thing');

    $log->debug("---");
    $log->debug("--- GET metric $thing");
    $log->debug("---");

    $self->do_render($self->$thing);
}

sub do_render {
    my $self    = shift;
    my $href    = shift;
    $self->render(
        json    => $href,
        code    => 200,
    );
}

sub get_request_params {
    my $self    = shift;
    return $self->req->params->to_hash;
}

# http://bl.ocks.org/tjdecke/5558084
sub day_hour_heatmap {
    my $self        = shift;
    my $env         = $self->env;
    my $log         = $env->log;
    my $mongo       = $env->mongo;
    my $request     = $self->get_request_params;
    my $collection  = $request->{collection} // 'event';
    my $type        = $request->{type} // 'created';
    my $year        = $request->{year} // $self->get_this_year;
    my $query       = {
        metric  => qr/$collection $type/,
        year    => $year,
    };

    my $cursor  = $mongo->collection('Stat')->find($query);
    my %results;
    while ( my $stat = $cursor->next ) {
        # doesn't work as expected because GMT 
        # $results{$stat->dow}{$stat->hour} += $stat->value;
        # once this is fixed, can probably collapse the two loops into one
        my $dt  = DateTime->from_epoch(epoch=>$stat->epoch);
        $dt->set_time_zone('America/Denver'); # TODO: move to config
        $results{$dt->dow}{$dt->hour} += $stat->value;
    }
    my @r   = ();
    for (my $dow = 1; $dow <= 7; $dow++) {
        for (my $hour = 0; $hour <= 23; $hour++) {
            my $value = $results{$dow}{$hour};
            push @r, { day => $dow, hour => $hour, value => $value };
        }
    }
   return \@r;
}

sub apply_prod_hour_filter {
    my $self    = shift;
    my $stat    = shift;
    my $limit   = shift;
    my $log     = $self->env->log;


    if ( defined $limit and $limit ne "production" ) {
        $log->warn("limit not set or not production");
        return undef;
    }
    $log->debug("limit is set to production");
    my $tz  = $self->env->time_zone;
    my $ldt = DateTime->from_epoch( epoch => $stat->epoch );
    $ldt->set_time_zone($tz);

    # logic switches at this point because we want to "next" skip
    # if not within production hours

    if ($ldt->dow < 6) {
        $log->debug("we are looking at a prod day");
        if ( $ldt->hour < 18 and $ldt->hour >= 6 ) {
            $log->debug("we are in prod hours");
            return undef;
        }
        $log->debug("not in prod hours");
        return 1;
    }
    else {
        $log->debug("not in prod day");
        return 1;
    }
}

sub generate_range_match {
    my $self        = shift;
    my $range       = shift;
    my $metric      = shift;
    my $rtype       = shift;

    my $match       = {
    #    year    => {'$lte' => $range->[1]->year, '$gte' => $range->[0]->year },
    #    month   => {'$lte' => $range->[1]->month,'$gte' => $range->[0]->month },
    #    day     => {'$lte' => $range->[1]->day,  '$gte' => $range->[0]->day },
    #    hour    => {'$lte' => $range->[1]->hour, '$gte' => $range->[0]->hour },
        epoch   => { '$lte' => $range->[0]->epoch, '$gte' => $range->[1]->epoch },
    };
    if ( defined $metric ) {
        $match->{metric} = $metric;
    }
    return $match;
}

sub get_alltime_alert_responsetime_avg {
    my $self    = shift;
    my $target  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $tdt;
    if ( defined $target ) {
        $tdt    = $env->date_util->parse_datetime_string($target);
    }
    else {
        $tdt    = DateTime->now();
    }


    my @range   = $env->date_util->get_time_range({range=>"lastyear"}, $tdt);
    my $regex   = qr/Alertgroup Response Time/;
    my $match   = $self->generate_range_match(\@range, $regex);
    my @agg     = (
        {
            '$match'    => $match,
        },
        {
            '$group'    => {
                _id => '$metric',
                sum => { '$sum' => '$value' },
            },
        }
    );
    my $collection  = $mongo->collection('Stat');
    my $aggcursor   = $collection->get_aggregate_cursor(\@agg);
    my %results     = ();
    while ( my $href = $aggcursor->next ) {
        my $metric = $href->{_id};
        my $value   = $href->{sum};
        my @w       = split(/ /,$metric);
        my $type    = $w[0]; # Sum or Count
        my $subtype = $w[2]; # all, promoted, incident
        $results{$type}{$subtype} += $value;
    }

    my %r = ();

    foreach my $t (qw(all promoted incident)) {
        if ( $results{Count}{$t} != 0 ) {
            $r{$t} = $results{Sum}{$t} / $results{Count}{$t};
        }
    }
    return wantarray ? %r : \%r;
}

sub response_avg_last_x_days {
    my $self        = shift;
    my $env         = $self->env;
    my $log         = $env->log;
    my $mongo       = $env->mongo;
    my $request     = $self->get_request_params;
    my $x           = $request->{days};
    my $limit       = $request->{limit}; # prod or all
    my $dt;
    if ( $request->{targetdate} ) {
        $dt = $env->date_util->parse_datetime_string($request->{targetdate});
    }
    else {
        $dt = DateTime->today();
    }
    my $json    = {};

    my $averages = $self->get_alltime_alert_responsetime_avg;
    ## want-> json = {
    ##     lines: [ { name: " ", value: x },...], 
    ##     dates: [ { date: " ",name:" ", value: x }...]
    ## }
    push @{$json->{lines}}, 
        { name => "All Avg", value => $averages->{all} // 0 },
        { name => "Promoted Avg", value => $averages->{promoted} // 0},
        { name => "Incident Avg", value => $averages->{incident} // 0};



    for ( my $i = $x-1; $i >= 0; $i-- ) {
        my $next_start_dt   = $dt->clone();
        $next_start_dt->subtract(days => $i);
        my $next_end_dt     = $next_start_dt->clone();
        $next_end_dt->set(hour=>23, minute=>59, second=>59);
        my $request = {
            range   => [ $next_start_dt, $next_end_dt ]
        };
        if ( defined $limit ) {
            $request->{limit} = $limit;
        }
        my $dayresult   = $self->response_time($request);
        push @{$json->{dates}}, {
            date    => $next_start_dt->ymd('-'),
            values  => [
                { 
                    name  => 'All', 
                    value => $dayresult->{all}->{avg} // 0
                },
                { 
                    name  => 'Promoted', 
                    value => $dayresult->{promoted}->{avg} // 0
                },
                { 
                    name  => 'Incident', 
                    value => $dayresult->{incident}->{avg} // 0
                },
            ],
        };
    }
    return $json;

}
        

sub response_time {
    my $self        = shift;
    my $request     = shift // $self->get_request_params;
    my $env         = $self->env;
    my $log         = $env->log;
    my $mongo       = $env->mongo;
    my @range       = $env->date_util->get_time_range($request);
    my $limit       = $request->{limit};

    my $collection  = $mongo->collection('Stat');
    my $regex       = qr/Alertgroup Response Times/;
    my $match       = $self->generate_range_match(\@range,$regex);
    $log->debug("response_time match is ",{filter=>\&Dumper, value => $match});
    my $cursor      = $collection->find($match);

    $log->debug("There are ".$cursor->count." items in range");

    my %results;
    while ( my $stat = $cursor->next ) {

        next if $self->apply_prod_hour_filter($stat,$limit);
                    
        my $metric  = $stat->metric;
        my @w       = split(/ /,$metric);
        my $type    = lc($w[0]); # Sum or Count
        my $subtype = lc($w[2]); # all, promoted, incident
        my $value   = $stat->value;
        next if ($value == 0);

        $log->debug("pushing $value onto \$results{$subtype}");

        push @{$results{$subtype}{$type}}, $stat->value;
    }

    my $json    = {
        all         => $self->get_statistics($results{all}),
        promoted    => $self->get_statistics($results{promoted}),
        incident    => $self->get_statistics($results{incident}),
    };

    return $json;
}

sub get_statistics_nogood {
    my $self    = shift;
    my $href    = shift; # { sum => [ x,y,z...], count => [a,b,c...] }
    my @values  = ();

    unless (defined $href) {
        return {};
    }

    $self->env->log->debug("HREF for stats = ",{filter=>\&Dumper, value=>$href});

    for ( my $i = 0; $i < scalar(@{$href->{sum}}); $i++ ) {
        my $sum = $href->{sum}->[$i];
        my $cnt = $href->{count}->[$i];
        if ( ! defined $cnt or $cnt == 0 ) {
            $cnt = 1;
        }
        my $avg = $sum/$cnt;
        push @values, $avg;
    } 
    my $util    = Statistics::Descriptive::Sparse->new();
       $util->add_data(@values);
    return {
        avg     => $util->mean,
        min     => $util->min,
        max     => $util->max,
        stddev  => $util->standard_deviation,
        count   => $util->count,
    };
}

sub get_statistics {
    my $self    = shift;
    my $aref    = shift; # array of values
    my $util    = Statistics::Descriptive::Sparse->new();
    
    $util->add_data(@{$aref});

    return {
        avg     => $util->mean,
        min     => $util->min,
        max     => $util->max,
        stddev  => $util->standard_deviation,
        count   => $util->count,
    };
}



sub creation_bullet {
    my $self    = shift;
    my $env         = $self->env;
    my $log         = $env->log;
    my $mongo       = $env->mongo;
    my @range       = $env->date_util->get_time_range({range=>"today"});
    my $dt          = DateTime->now();
    my $hour        = $dt->hour;

    my $collection  = $mongo->collection('Stat');
    my $regex       = qr/created$/;
    my $match       = $self->generate_range_match(\@range,$regex);
    my $cursor      = $collection->find($match);
    $log->debug("There are ".$cursor->count." items in range");

    my %results = ();
    while ( my $stat    = $cursor->next ) {
        my $metric  = $stat->metric;
        my @w       = split(/ /,$metric);
        my $type    = lc($w[0]);
        my $value   = $stat->value;
        next if ($value == 0);
        $log->debug("Pushing $value onto \$results{$type}");
        push @{ $results{$type} }, $value;
    }
    my @json    = ();

    foreach my $t (qw(alertgroups event incident entry)) {
        $log->debug("getting stats on ",{filter=>\&Dumper, value=>$results{$t}});
        my $stat = $self->get_statistics($results{$t});
        push @json, {
            title   => ucfirst($t). " Creation",
            subtitle    => "count",
            ranges  => [ $stat->{avg} - $stat->{stddev},
                         $stat->{avg} + $stat->{stddev} ],
            measures => [ $stat->{count}, $stat->{count} * (24 - $hour) ],
            markers => $stat->{avg},
        };
    }
    return \@json;
}

sub create_histo {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my @range   = $env->date_util->get_time_range({range => "thisweek"});
    my $dt      = DateTime->now();
    my $hour    = $dt->hour;

    $log->debug("creation histo");

    my $collection  = $mongo->collection('Stat');
    my $regex       = qr/created$/;
    my $match       = $self->generate_range_match(\@range,$regex, "thisweek");

    $log->debug("mongo query is ",{filter=>\&Dumper, value=>$match});
    my $cursor      = $collection->find($match);

    my %results     = ();

    $log->debug("got ".$cursor->count." results");

    while (my $stat = $cursor->next ) {
        my $metric  = $stat->metric;
        my $type    = lc( (split(/ /,$metric))[0] );
        my $value   = $stat->value;

        next if ($value == 0);

        my $epochdt   = DateTime->new(
            year    => $stat->year,
            month   => $stat->month,
            day     => $stat->day,
        );
        $results{$type}{$epochdt->epoch} += $value;
    }

    $log->debug("results are ",{filter=>\&Dumper, value=>\%results});

    my @json    = ();

    foreach my $type (sort keys %results) {
        my @vals = ();

        foreach my $epoch (sort keys %{$results{$type}}) {
            push @vals, {
                time    => $epoch,
                value   => $results{$type}{$epoch},
            };
        }

        my $href    = {
            name    => $type,
            data    => \@vals,
        };
        $log->debug("pushing ",{filter=>\&Dumper, value=>$href});
        push @json, $href;
    }

    $log->debug("json ",{filter=>\&Dumper, value=>\@json});
    return \@json;

}

sub alert_breakdown_last_x_days {
    my $self        = shift;
    my $env         = $self->env;
    my $log         = $env->log;
    my $mongo       = $env->mongo;
    my $request     = $self->get_request_params;
    my $x           = $request->{days};
    my $dt;

    $log->debug("alert breakdown metric calculation begins");

    if ( $request->{targetdate} ) {
        $dt = $env->date_util->parse_datetime_string($request->{targetdate});
    }
    else {
        $dt = DateTime->today();
    }

    my @results = ();
    for (my $i = $x-1; $i >= 0; $i--) {
        my $nsdt     = $dt->clone();
        $nsdt->subtract(days => $i);
        my $nedt    = $nsdt->clone();
        $nedt->set(hour => 23, minute => 59, second => 59);
        my $req = {
            range   => [ $nsdt, $nedt ],
        };
        my $dayresult = $self->alert_breakdown($req);
        my $row = { 
            date        => $nsdt->ymd('-'),
            open        => $dayresult->{"open"} // 0,
            closed      => $dayresult->{"closed"} // 0,
            promoted    => $dayresult->{"promoted"} // 0,
        };
        push @results, $row;

    }
    return \@results;
}

sub alert_breakdown {
    my $self    = shift;
    my $request     = shift // $self->get_request_params;
    my $env         = $self->env;
    my $log         = $env->log;
    my $mongo       = $env->mongo;
    my @range       = $env->date_util->get_time_range($request);

    $log->debug("alert_breakdown");

    my $collection  = $mongo->collection('Stat');
    my $regex       = qr/[a-z]+ alert count$/;
    my $match       = $self->generate_range_match(\@range,$regex);
    $log->debug("matching ",{filter=>\&Dumper, value=> $match});
    my $cursor      = $collection->find($match);

    $log->debug("found ".$cursor->count." matching stat records");

    my %results = ();
    while (my $stat = $cursor->next ) {
        my $metric      = $stat->metric;
        my $value       = $stat->value;
        $log->debug($stat->year."/".$stat->month."/".$stat->day." ".$stat->metric . " ".$stat->value);
        my ($type,$junk) = split(/ /,$metric,2);
        $results{$type} += $value;
    }
    return wantarray ? %results : \%results;
}

sub alert_power {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $request = $self->get_request_params;

    my $report  = $request->{report}; # all, top10, bottom10
    my $sums    = $self->alert_power_sums($request);

    my @results = ();
    foreach my $at (keys %$sums) {
        push @results, {
            name        => $at,
            open        => $sums->{$at}->{open},
            promoted    => $sums->{$at}->{promoted},
            incident    => $sums->{$at}->{incident},
            score       => $sums->{$at}->{score},
        };
    }

    $log->debug("results: ",{filter=>\&Dumper,value=>\@results});

    # @results    = map { delete $_->{score}; $_ } sort { $b->{score} <=> $a->{score} } @results;
    my @sorted    = sort { $b->{score} <=> $a->{score} } @results;

    $log->debug("sorted results: ",{filter=>\&Dumper,value=>\@sorted});


    # my @slice = splice(@sorted, 0, 20);
    # $log->debug("Slice is ",{filter=>\&Dumper, value=>\@slice});
    # return \@slice;
    return \@sorted;
}


sub alert_power_sums {
    my $self    = shift;
    my $request = shift;
    my $target  = $request->{target};
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $tdt;
    if ( defined $target ) {
        $tdt    = $env->date_util->parse_datetime_string($target);
    }
    else {
        $tdt    = DateTime->now();
    }


    my @range   = $env->date_util->get_time_range({range=>"thisyear"}, $tdt);
    my $match   = $self->generate_range_match(\@range, undef);
    my $stype   = $request->{sort};
    my $sort    = $request->{dir} eq "asc" ? 1 : -1;
    my $limit   = $request->{count} // 10;
    $limit += 0;
    my @agg     = (
        {
            '$match'    => $match,
        },
        {
            '$group'    => {
                _id => '$alerttype',
                open        => { '$sum' => '$open' },
                promoted    => { '$sum' => '$promoted' },
                incident    => { '$sum' => '$incident' },
            },
        },
        {
            '$sort' => {
                $stype  => $sort
            },
        },
        {
            '$limit'    => $limit
        },
    );
    $log->debug("running agg command: ",{filter=>\&Dumper, value=>\@agg});
    my $collection  = $mongo->collection('Atmetric');
    my $aggcursor   = $collection->get_aggregate_cursor(\@agg);
    my %r = ();
    while ( my $href = $aggcursor->next ) {
        my $score   = $self->calculate_score($href);
        $r{$href->{_id}} = {
            open        => $href->{open},
            promoted    => $href->{promoted},
            incident    => $href->{incident},
            score       => $score,
        };
    }
    $log->debug("alert type sums:",{filter=>\&Dumper,value=>\%r});
    return wantarray ? %r : \%r;
}

sub calculate_score {
    my $self        = shift;
    my $href        = shift;
    my $log         = $self->env->log;
    my $multiple    = 2;
    my $total       = $href->{promoted} + $href->{open};
    
    my $score   = 0;
#    if ( $total > 0 ) {
#        $score = (($href->{promoted} + ($multiple * $href->{incident}) )/$total);
#    }
    $score  = $href->{promoted} + $multiple*$href->{incident};# - $href->{open};
    # return int($score * 1000);
    return $score;
}

sub get_game_data {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $user    = $self->session('user');
    my $tt      = {
        teacher     => "Most Guide Entries Authored",
        tattler     => "Most Incidents Promoted",
        alarmist    => "Most Alerts Promoted",
        closer      => "Most Closed things",
        cleaner     => "Most Deleted Things",
        fixer       => "Most Edited Entries",
        operative   => "Most Intel Entries",
    };

    my $col = $mongo->collection('Game');
    my $cur = $col->find();
    my %res = ();

    while ( my $gobj = $cur->next ) {
        my $results_aref    = $gobj->results;
        my $name            = $gobj->game_name;
        my $tip             = $gobj->tooltip;
        my $updated         = $gobj->lastupdate;

        $res{$name} = [
            { username => $results_aref->[0]->{_id},
              count    => $results_aref->[0]->{total}, 
              tooltip   => $tip, 
            },
            { username => $results_aref->[1]->{_id},   
              count    => $results_aref->[1]->{total},
              tooltip   => $tip, 
            },
            { username => $results_aref->[2]->{_id},   
              count    => $results_aref->[2]->{total},
              tooltip   => $tip, 
            },
        ];
    }

    $self->do_render(\%res);

}

sub get_status {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my $status_file = "/opt/scot/data/status.txt";
    my @statuses    = ();

    try {
        @statuses = read_file($status_file);
    }
    catch {
        $log->error("Unable to read file $status_file: $_");
    };

    my @return  = ();
    foreach my $line (@statuses) {
        my ($daemon, $status) = split(/=/,$line);
        push @return, { name => $daemon, status => $status };
    }

    $self->do_render(\@return);
}
#    my $status  = [
#        { name  => "Scot Flair",    status => $self->get_daemon_status('scfd') },
#       { name  => "Scot Elastic",  status => $self->get_daemon_status('scepd') },
#        { name  => "Scot App",      status => $self->get_daemon_status('scfd') },
#        { name  => "Scot Reflair",  status => $self->get_daemon_status('scrfd') },
#        { name  => "Scot Mongodb",  status => $self->get_daemon_status('mongod') },
#    ];

sub get_daemon_status {
    my $self    = shift;
    my $daemon  = shift;
    my $log     = $self->env->log;

    my $systemd = `systemctl | grep "\-\.mount"`;

    if ( $systemd =~ /-\.mount/ ) {
        $log->debug("systemd style services!");
        my $result  = `service $daemon status`;
        my @statuses  = ();
        foreach my $line (split(/\n/,$result)) {
            next unless ( $line =~ / +\S+:/ );
            my ($type, $data) = split(/: /,$line);
            if ( $type =~ /Active/ ) {
                push @statuses, $data;
                if ( $data =~ /running/i ) {
                    return "ok";
                }
                if ( $data =~ /dead/i ) {
                    return "error";
                }
            }
        }
        return join(' ',reverse @statuses);
    }

    my $result  = `service $daemon status`;
    $log->debug("DAEMON status is $result");
    my ($status)=  $result =~ /.*\[(.*)\]/; 
    $log->debug("plucked $status");
    return $result;
}

sub get_who_online {
    my $self    = shift;
    my $env     = $self->env;
    my $now     = $env->now;
    my $ago     = 30 * 60;   # activity in last 30 minutes
    my $col     = $env->mongo->collection('User');
    my $cur     = $col->find({ lastvisit => { '$gte' => $now - $ago }});
    $cur->sort({lastvisit => -1});
    my $total   = $cur->count;
    my @results = ();

    while (my $user = $cur->next ) {
        push @results, {
            username        => $user->username,
            last_activity   => $now - $user->lastvisit,
        };
    }
    $self->do_render({
        records             => \@results,
        queryRecordCount    => scalar(@results),
        totalRecordCount    => $total

    });
}

1;
