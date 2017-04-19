package Scot::App::Metric;

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
use Log::Log4perl::Level;
use Statistics::Descriptive;
use Data::Dumper;
use MongoDB::Code;
use Moose;
extends 'Scot::App';

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
        
sub alert_response_time {
    my $self    = shift;
    my $startdt = shift;
    my $enddt   = shift;
    my $mongo   = $self->env->mongo;
    my $statcol = $mongo->collection('Stat');
    my $aggcmd  = $self->build_response_time_aggregation($startdt,$enddt);
    my $aggcol  = $mong->collection('Alert');

}

sub build_response_time_aggregation {
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
                dt  => {
                    '$add'  => [
                        DateTime->from_epoch( epoch => 0 ),
                        { '$multiply' => [ '$created', 1000 ] }
                    ]
                },
            }
        },




1;
