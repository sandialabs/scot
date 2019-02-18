package Scot::Controller::Stat;

use lib '../../../lib';
use strict;
use warnings;
use Data::Dumper;
use Mojo::JSON qw(decode_json encode_json);
use DateTime;
use DateTime::Duration;
use Statistics::Descriptive;

use base 'Mojolicious::Controller';

sub get {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $thing   = $self->stash('thing');
    
    $log->debug("--- ");
    $log->debug("--- GET viz");
    $log->debug("--- ");

    return $self->pyramid_json           if ( $thing eq "pyramid" );
    return $self->day_hour_heatmap_json  if ( $thing eq "dhheatmap" );
    return $self->day_hour_heatmap_json2 if ( $thing eq "dhheatmap2" );
    return $self->get_statistics_json    if ( $thing eq "statistics" );
    return $self->get_stats_this_dow     if ( $thing eq "todaystats" );
    return $self->get_bullet_data        if ( $thing eq "bullet" );
    return $self->alert_response         if ( $thing eq "alertresponse" );

}

sub do_render {
    my $self    = shift;
    my $code    = 200;
    my $href    = shift;
    $self->render(
        json    => $href,
        status  => $code,
    );
}

sub get_request_params {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $params  = $self->req->params->to_hash;

    return $params;
}

sub get_seconds {
    my $self    = shift;
    my $d       = shift;
    my $u       = shift;
    my $t       = 0;

    my $s = 60;

    $s = $s * 60 if ( $u eq "hour" );
    $s = $s * 60 * 24 if ( $u eq "day" );
    $s = $s * 60 * 24 * 30 if ( $u eq "month" ); # close enough
    $s = $s * 60 * 24 * 90 if ( $u eq "quarter" ); # for govt. work

    return $s;
}

sub pyramid_json {
    my $self        = shift;
    my $req_href    = $self->get_request_params;
    my $log         = $self->env->log;

    $log->debug("requested params are ",{filter=>\&Dumper, value=>$req_href});

    my $span_type   = $req_href->{span_type}; # ... day, month, quarter, year
    my $index       = $req_href->{index} + 0; # ... number of span_types ago to tally

    # pyramid report returns:
    # {
    #   alerts: int,
    #   events: int,
    #   incidents: int,
    # }

    my $st  = $span_type."s";

    my $nowdt       = DateTime->from_epoch( epoch => $self->env->now );
    if ( $span_type ne "all") {
        my $duration    = DateTime::Duration->new(
            $st  => $index,
        );
        $nowdt->subtract_duration($duration);
    }

    $log->debug("Looking for $span_type pyramid $index on ".$nowdt->ymd);

    my $createdre   = qr{created}i;

    my $match   = {
        metric  => $createdre,
    };
    if ($span_type eq "day") {
        $match->{year} = $nowdt->year;
        $match->{month} = $nowdt->month;
        $match->{day} = $nowdt->day;
    }
    if ($span_type eq "month") {
        $match->{year} = $nowdt->year;
        $match->{month} = $nowdt->month;
    }
    if ($span_type eq "quarter") {
        $match->{year} = $nowdt->year;
        $match->{quarter} = $nowdt->quarter;
    }
    if ($span_type eq "year") {
        $match->{year} = $nowdt->year;
    }
    if ($span_type eq "all") {
        # do nothing;
    }

    $log->debug("match is ",{ filter=>\&Dumper, value=>$match });

    my $cursor  = $self->env->mongo->collection('Stat')->find($match);
    my $json;

    while ( my $obj = $cursor->next ) {
        my $type    = ( split(/ /,$obj->metric) )[0];
        $json->{$type} += $obj->value;
    }

    $self->do_render($json);

}

# http://bl.ocks.org/tjdecke/5558084
sub day_hour_heatmap_json {
    my $self        = shift;
    my $log         = $self->env->log;
    my $req_href    = $self->get_request_params;
    my $collection  = $req_href->{collection} // 'event';
    my $type        = $req_href->{type} // 'created' ; # ... created | updated|...
    my $year        = $req_href->{year}+0 // 2016;
    my $metricre    = qr/$collection $type/;
    my $match   = {
        metric  => $metricre,
        year    => $year,
    };
    $log->debug("building day hour heatmap for ",{filter=>\&Dumper, value=>$match});
    my $cursor  = $self->env->mongo->collection('Stat')->find($match);
    # $log->debug("cursor has ".$cursor->count." document");
    my %results = ();
    while ( my $obj = $cursor->next ) {
        my $dt  = DateTime->from_epoch( epoch => $obj->epoch );
        $dt->set_time_zone("America/Denver");
        $results{$dt->dow}->{$dt->hour} += $obj->value;
    }
    my @resarray; #  = (
    #    [ 'day', 'hour', 'value' ]
    #);

    for (my $dow = 1; $dow <= 7; $dow++) {

        for (my $hour = 1; $hour <=24; $hour++) {
            my $value   = defined $results{$dow}{$hour} ? $results{$dow}{$hour} : 0;
            push @resarray, { 
                day     => $dow, 
                hour    => $hour, 
                value   => $value,
            };
        }
    }
    $self->do_render(\@resarray);
}

sub day_hour_heatmap_json_2 {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $req     = $self->get_request_params;
    my $col     = $req->{collection} // 'event';
    my $type    = $req->{type} // 'created';
    my $year    = $req->{year} + 0 // 2018;
    my $mre     = qr/$col $type/;
    my $match   = {
        metric  => $mre,
        year    => $year,
    };

    my $cursor  = $mongo->collection('Stat')->find($match);
    my %results = ();
    while ( my $obj = $cursor->next ) {
        my $dt  = DateTime->from_epoch( epoch => $obj->epoch );
        $dt->set_time_zone('America/Denver');
        $results{$dt->dow}{$dt->hour} += $obj->value;
    }

    my @dowres = ();
    for ( my $dow = 1; $dow <= 7; $dow ++ ) {
        my @hres  = ();
        for ( my $h = 1; $h <= 24; $h++ ) {
            my $value = defined $results{$dow}{$h} ? $results{$dow}{$h} : 0;
            push @hres, $value;
        }
        push @dowres, \@hres;
    }
    $self->do_render(\@dowres);
}



sub get_stats_this_dow {
    my $self    = shift;
    my $req_href= $self->get_request_params;
    my $results = $self->get_dow_stats;
    $self->do_render($results);
    
}

sub get_dow_stats {
    my $self    = shift;
    my $env     = $self->env;
    my $results = {};
    my $dt      = DateTime->from_epoch( epoch => $env->now );
    my $dow     = $dt->dow;
    my $col     = $env->mongo->collection('Stat');
    my %metrics = (
        "alert"    => "alert created",
        "event"    => "event created",
    );

    foreach my $metric (sort keys %metrics) {
        $results->{$metric} = 
            ($col->get_dow_statistics($metrics{$metric}))[$dow];
    }
    return $results;
}

sub get_statistics_json {
    my $self        = shift;
    my $req_href    = $self->get_request_params;
    my $log         = $self->env->log;

    $log->debug("Getting statistics");

    my $collection  = $self->env->mongo->collection('Stat');
    $log->debug("req_href is ",{filter=>\&Dumper,value=>$req_href});
    my $metric          = $req_href->{metric};
    my ($today,$count)  = $collection->get_today_count($metric);
    my $href            = ($collection->get_dow_statistics($metric))[$today];
    $href->{dow}    = $today;
    $href->{count}  = $count;
    $self->do_render($href);

}

sub get_bullet_data {
    my $self    = shift;
    # generate data of the form:
    # [ { title: "metric title", subtitle: "yep", ranges: [ x,y,z ], measures: [a,b], markers: [c]},...]
    my $log = $self->env->log;
    my @results = ();
    my $collection  = $self->env->mongo->collection('Stat');

    my $dt      = DateTime->from_epoch( epoch => $self->env->now );
    my $hour    = $dt->hour;

    for my $colname (qw(alert event incident entry)) {
        my $metric  = "$colname created";
        my ($today, $count) = $collection->get_today_count($metric);
        $log->debug("today $today count $count");
        my $stats   = $self->get_dow_stats();
        $log->debug("Stats: ",{filter=>\&Dumper, value => $stats});
        my $below   = $stats->{$colname}->{value}->{avg} - $stats->{stddev};
        my $above   = $stats->{$colname}->{value}->{avg} + $stats->{stddev};
        my $expected    = $count * ( 24 - $hour);
        my $result  = {
            title       => $metric,
            subtitle    => "count",
            ranges      => [ $below, $above ],
            measures    => [ $count, $expected ],
            markers     => $stats->{$colname}->{value}->{avg},
        };
        push @results, $result;
    }
    $self->do_render(\@results);
}

sub get_time_range {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $type    = $href->{type} // 'month'; # or quarter or year
    my $dt      = DateTime->from_epoch( epoch => $env->now );
    my $month   = $dt->month;
    my $year    = $dt->year;
    if ( $type eq "month" ) {
        my $year    = defined $href->{year}  ? $href->{year}  : $dt->year;
        my $month   = defined $href->{month} ? $href->{month} : $dt->month;
        my $ldt     = DateTime->last_day_of_month(
            year    => $year,
            month   => $month,
        );
        $ldt->set( hour => 23, minute => 59, second => 59 );
        my $startdt = DateTime->new(
            year    => $ldt->year,
            month   => $ldt->month,
            day     => 1,
            hour    => 0,
            minute  => 0,
            second  => 0,
        );
        return $startdt, $ldt;
    }
    # else quarter
    my $targetqtr = $href->{quarter}; # 17Q2 or YYQ[1-4]
    my $targetfy  = $href->{fy};
    my ($startdt, $enddt) = $self->get_start_stop_sandia_fyq($targetfy, $targetqtr);
    return $startdt, $enddt;

}

sub get_quarter {
    my $self    = shift;
    my $month   = shift;
    # TODO: move to config
    my %qtrs    = (
        1       => 2,
        2       => 2,
        3       => 2,
        4       => 3,
        5       => 3,
        6       => 3,
        7       => 4,
        8       => 4,
        9       => 4,
        10      => 1,
        11      => 1,
        12      => 1,
    );
    return $qtrs{$month};
}

sub get_start_stop_sandia_fyq {
    my $self    = shift;
    my $fy      = shift;
    my $qtr     = shift;

    my ($startmonth, $endmonth, $endday);
    my $year    = "20" . $fy;
    if ( $qtr == 1 ) {
        $year--;
        $startmonth = 10;
        $endmonth   = 12;
        $endday     = 31;
    }
    if ( $qtr == 2 ) {
        $startmonth = 1;
        $endmonth   = 3;
        $endday     = 31;
    }
    if ( $qtr == 3 ) {
        $startmonth = 4;
        $endmonth   = 6;
        $endday     = 30;
    }
    if ( $qtr == 4 ) {
        $startmonth = 7;
        $endmonth   = 9;
        $endday     = 30;
    }
    my $startdt = DateTime->new(
        year    => $year,
        month   => $startmonth,
        day     => 1,
        hour    => 0,
        minute  => 0,
        second  => 0,
    );
    my $enddt = DateTime->new(
        year    => $year,
        month   => $endmonth,
        day     => $endday,
        hour    => 23,
        minute  => 59,
        second  => 59,
    );
    return $startdt, $enddt;
}
        

sub get_max {
    my $self    = shift;
    my $a       = shift;
    my $b       = shift;
    return ($a,$b)[$a < $b];
}

sub get_min {
    my $self    = shift;
    my $a       = shift;
    my $b       = shift;
    return ($a,$b)[$a > $b];
}

sub during_production {
    my $self    = shift;
    my $dt      = shift;
    my $dow     = $dt->dow;
    my $hour    = $dt->hour;

    if ( $dow < 6 ) {
        if ( $hour < 18 and $hour >= 6 ) {
            return 1;
        }
    }
    return undef;
}

sub get_earliest_view {
    my $self        = shift;
    my $alertgroup  = shift;
    my $href        = $alertgroup->view_history;
    my @times       = sort { $a <=> $b }
                      grep { $_ == $_ }
                      map  { $href->{$_}->{when} }
                      keys  %{$href};
    foreach my $t (@times) {
        return $t if ($t != 0);
    }
    return undef;
}


sub alert_response {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $req_href    = $self->get_request_params;
    my ($startdt, $enddt) = $self->get_time_range($req_href);

    $log->debug("Building alert response time stats");

    my $agcol   = $mongo->collection('Alertgroup');
    my $cursor  = $agcol->find({
         status => "promoted" ,
         when  => { '$lte' => $enddt->epoch ,
                    '$gte' => $startdt->epoch },
    });
    $cursor->sort({id => 1});

    my @prod    = ();
    my @all     = ();
    my @clear;  
    while ( my $alertgroup = $cursor->next ) {
        my $dt  = DateTime->from_epoch( epoch => $alertgroup->when );
        # TODO: move this to a configuration item in scot.cfg.pl
        $dt->set_time_zone('America/Denver');
        # TODO: define production days/hours in config

        if ( $self->during_production($dt) ) {
            my $first_view_epoch = $self->get_earliest_view($alertgroup);
            if (defined $first_view_epoch) {
                my $delta = $first_view_epoch - $alertgroup->when;
                if ( $delta > 0 ) {
                    push @prod, $delta;
                }
            }
        }
        my $first_view_epoch = $self->get_earliest_view($alertgroup);
        if (defined $first_view_epoch) {
            my $delta = $first_view_epoch - $alertgroup->when;
            if ( $delta > 0 ) {
                push @all, $delta;
            }
        }
    }

    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@prod);
    
    my $final   = {
        prod    => {
            mean    => $stat->mean(),
            var     => $stat->variance(),
            sd      => $stat->standard_deviation(),
            mode    => $stat->mode(),
            count   => $stat->count(),
            max     => $stat->max(),
            min     => $stat->min(),
        },
    };

    $stat->add_data(@clear);
    $stat->add_data(@all);

    $final->{all} = {
        mean    => $stat->mean(),
        var     => $stat->variance(),
        sd      => $stat->standard_deviation(),
        mode    => $stat->mode(),
        count   => $stat->count(),
        max     => $stat->max(),
        min     => $stat->min(),
    };

    $self->do_render($final);

}




        
1;
