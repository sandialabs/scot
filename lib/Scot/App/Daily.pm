package Scot::App::Daily;

use lib '../../../lib';
use lib '/opt/scot/lib';
use strict;
use warnings;
use v5.18;

use Data::Dumper;
use DateTime;
use DateTime::Duration;
use Try::Tiny;
use Scot::Env;
use Scot::Util::Date;
use Log::Log4perl::Level;
use Statistics::Descriptive;
use Data::Dumper;
use Email::Stuffer;
use MongoDB::Code;
use Moose;
extends 'Scot::App';

sub daily_briefing {
    my $self    = shift;
    my $date    = shift;
    my $env     = $self->env;
    my $mets    = $env->mets;
    my $mongo   = $env->mongo;

    unless (defined $date) {
        $date            = $mets->get_yesterday;
    }
    my $dcount          = $mets->get_count_dev('alert', $date);
    $env->log->debug("dcount is ",{filter=>\&Dumper, value=>$dcount});
    my $response        = $mets->get_avg_response_time($date->epoch,"day");
    my $text    = sprintf(qq|
--------------------------------------------------
Scot Daily Brief for %s
--------------------------------------------------

Alerts Received     : %6d 
Events Created      : %6d 
Incidents Created   : %6d

Avg. Response Time to Alerts
%s

|, 
    $date->ymd,
    $dcount->{alert}->{count},
    $dcount->{event}->{count},
    $dcount->{incident}->{count},
    $mets->get_human_time($response->{all}),
);

    my $start = DateTime->new(
        year    => $date->year,
        month   => $date->month,
        day     => $date->day,
        hour    => 0,
    );
    my $end  = DateTime->new(
        year    => $date->year,
        month   => $date->month,
        day     => $date->day,
        hour    => 23,
        minute  => 59,
        second  => 59
    );

    $text .= $self->get_incidents($start,$end);
    $text .= $self->get_events($start,$end);

    $self->mail($text);
}

sub get_incidents {
    my $self    = shift;
    my $start   = shift;
    my $end     = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my $match   = {
        created => {
            '$lte'  => $end->epoch,
            '$gte'  => $start->epoch,
        }
    };

    $log->debug("incidents matching ",{filter=>\&Dumper, value=>$match});


    my $incidentcur = $mongo->collection('Incident')->find($match);
    my $inccount    = $mongo->collection('Incident')->count($match);

    if ( defined $incidentcur and $inccount > 0 ) {

        my $text = qq|
==
== Incidents
==
|;
        while ( my $obj = $incidentcur->next ) {
            my $scur    = $mongo->collection('Entry')->get_target_summary($obj);
            my @summary;
            while (my $s = $scur->next ) {
                push @summary, $s->body_plain;
            }
            $text .= sprintf(qq|[%5d] %40s\n\t%s\n\t%s|,
                $obj->id, 
                $obj->subject, 
                join('\n',@summary), 
                $env->dailybrief->{url}."/#/incident/".$obj->id
            );

        }
        return $text;
    }
    $log->error("no matching incidents");
}

sub get_events {
    my $self    = shift;
    my $start   = shift;
    my $end     = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;

    my $eventcur =
        $mongo->collection('Event')
              ->find({
                    created => {
                        '$lte'  => $end->epoch,
                        '$gte'  => $start->epoch,
                    }
                });
    my $eventcount  = $mongo->collection('Event')
              ->count({
                    created => {
                        '$lte'  => $end->epoch,
                        '$gte'  => $start->epoch,
                    }
                });

    if ( defined $eventcur and $eventcount > 0 ) {

        my $text = qq|
==
== Events
==
|;
        while ( my $obj = $eventcur->next ) {
            my $scur    = $mongo->collection('Entry')->get_target_summary($obj);
            my @summary;
            while (my $s = $scur->next ) {
                push @summary, $s->body_plain;
            }
            $text .= sprintf(qq|[%5d] %40s\n\t%s\n\t%s|,
                $obj->id, 
                $obj->subject, 
                join('\n',@summary), 
                $env->dailybrief->{url}."#/event/".$obj->id
            );

        }
        return $text;
    }
}

sub mail {
    my $self    = shift;
    my $text    = shift;
    my $env     = $self->env;
    Email::Stuffer->from($env->dailybrief->{mail}->{from})
                  ->to  ($env->dailybrief->{mail}->{to})
                  ->subject("Scot Daily Brief")
                  ->text_body($text)
                  ->transport('SMTP', { host => $env->dailybrief->{mail}->{host} })
                  ->send;
}



1;
