package Scot::Util::Metrics;

use lib '../../../lib';
use strict;
use warnings;
use v5.18;

use Data::Dumper;
use DateTime;
use Time::Duration;
use Mojo::JSON qw(decode_json encode_json);
use Statistics::Descriptive;

use Moose;

has env => (
    is       => 'ro',
    isa      => 'Scot::Env',
    required => 1,
);

sub get_seconds {
    my $self        = shift;
    my $quantity    = shift;
    my $unit        = shift;
    my $seconds     = 3600 * $quantity;

    if ( $unit eq "hour" ) {
        return $seconds;
    }
    $seconds *= 24;
    if ( $unit eq "day" ) {
        return $seconds;
    }
    $seconds *= 30;
    if ( $unit eq "month" ) {
        return $seconds;
    }
    if ( $unit eq "quarter" ) {
        $seconds *= 90;
        return $seconds;
    }
    $seconds *= 365;
    return $seconds;
        
}

sub get_created_stats {
    my $self    = shift;
    my $epoch   = shift;
    my $rollup  = shift;    # day, month, year
    my $env     = $self->env;
    my $mongo   = $env->mongo;

    my $dt      = DateTime->from_epoch( epoch => $epoch );

    my $year    = $dt->year;
    my $month   = $dt->month;
    my $day     = $dt->day;

    my $match   = {
        metric  => qr/created/i,
    };

    $match->{day}   = $day   if ($rollup eq "day");
    $match->{month} = $month if ($rollup eq "month" or $rollup eq "day");
    $match->{year}  = $year;

    say "Match is ",Dumper($match);

    my $cursor  = $mongo->collection('Stat')->find($match);
    my %results = ();

    while (my $obj = $cursor->next) {
        my $type    = (split(/ /,$obj->metric))[0];
        my $value   = $obj->value;
        say "$type => $value";
        $results{$type} += $obj->value;
    }

    return wantarray ? %results : \%results;
}

sub get_created_year_avg {
    my $self    = shift;
    my $epoch   = shift;
    my $mongo   = $self->env->mongo;
    my $year    = $self->get_seconds(1,"year");
    my $yago    = $epoch - $year;
    my $match   = {
        metric  => qr/created/i,
        epoch   => { '$lte' => $epoch, '$gte' => $yago },
    };
    my $cursor  = $mongo->collection('Stat')->find($match);
    my %results = ();

    my $count   = 0;
    while (my $obj = $cursor->next) {
        my $type    = (split(/ /,$obj->metric))[0];
        $results{$type} += $obj->value;
        $count++;
    }

    foreach my $type (keys %results) {
        my $value   = $results{$type};
        my $avg     = $value/$count;
        $results{$type} = $avg;
    }

    return wantarray ? %results : \%results;
}

sub get_avg_response_time {
    my $self    = shift;
    my $epoch   = shift;
    my $rollup  = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;

    my $dt      = DateTime->from_epoch(epoch=>$epoch);

    my $match   = {
        metric  => qr/Alertgroup Response Times/i,
    };
    $match->{day}     = $dt->day if ( $rollup eq "day");
    $match->{month}   = $dt->month if ( $rollup eq "month" or $rollup eq "day");
    $match->{year}  = $dt->year;

    my $cursor  = $mongo->collection('Stat')->find($match);
    my %results = ();

    while ( my $stat = $cursor->next ) {
        my $metric  = $stat->metric;
        my @words   = split(/ /,$metric);
        my $type    = $words[0];
        my $flavor  = $words[2];
        $results{$flavor}{$type} += $stat->value;
    }

    my %stats;
    foreach my $flavor (keys %results) {
        my $sum = $results{$flavor}{Sum};
        my $cnt = $results{$flavor}{Count};

        if ( $cnt > 0 ) {
            $stats{$flavor} = $sum/$cnt;
        }
        else {
            $stats{$flavor} = "na";
        }
    }
    return wantarray ? %stats : \%stats;
}

sub get_human_time {
    my $self    = shift;
    my $seconds = shift;
    my $english = duration_exact($seconds);
    return $english;
}

sub get_yesterday {
    my $self    = shift;
    my $dt      = DateTime->from_epoch(epoch=>(time()-(60*60*24)));
    return $dt;
}

sub get_count_dev {
    my $self    = shift;
    my $type    = shift;
    my $dt      = shift;
    my $epoch   = $dt->epoch();
    my $counts  = $self->get_created_stats($epoch, "day");
    my $avgs    = $self->get_created_year_avg($epoch);
    my %results = ();

    say Dumper($counts);
    say Dumper($avgs);

    foreach my $value (qw(alert event incident)) {
        my $count = $counts->{$value};
        my $avg   = $avgs->{$value};
        $results{$value}{dev}   = ( $count - $avg )/ ($avg);
        $results{$value}{avg}   = $avg;
        $results{$value}{count} = $count // 0;
    }

    return wantarray ? %results : \%results;
}



1;
