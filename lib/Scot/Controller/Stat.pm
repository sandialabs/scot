package Scot::Controller::Stat;

use lib '../../../lib';
use v5.18;
use strict;
use warnings;
use Data::Dumper;
use Mojo::JSON qw(decode_json encode_json);
use DateTime;
use DateTime::Duration;

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

    return $self->pyramid_json          if ( $thing eq "pyramid" );
    return $self->day_hour_heatmap_json if ( $thing eq "dhheatmap" );
    return $self->get_statistics_json   if ( $thing eq "statistics" );

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
    $log->debug("cursor has ".$cursor->count." document");
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

sub get_statistics_json {
    my $self        = shift;
    my $req_href    = $self->get_request_params;
    my $log         = $self->env->log;

    my $collection  = $self->env->mongo->collection('Stat');
    $log->debug("req_href is ",{filter=>\&Dumper,value=>$req_href});
    my $metric      = $req_href->{metric};

    $log->debug("Getting statistics");

    my $json = $collection->get_dow_statistics($metric);
    $self->do_render($json);

}

        
1;
