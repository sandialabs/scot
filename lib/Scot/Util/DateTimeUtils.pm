package Scot::Util::DateTimeUtils;

use lib '../../../lib';
use strict;
use warnings;
use v5.10;

use Data::Dumper;
use DateTime;

use Moose;
use namespace::autoclean;

has timezone    => (
    isa         => 'Str',
    is          => 'rw',
    required    => 1,
    default     => 'America/Denver',
);


sub get_date_match_ref {
    my $self        = shift;
    my $params      = shift; # hashref 

    my $timefield   = $params->{timefield} // "created";
    my $dt          = $params->{dtref};
    my $duration    = $params->{duration};
    
    if (!defined($dt) or ref($dt) ne "DateTime") {
        $dt = DateTime->now;
    }

    unless (grep {/$duration/} qw(day month quarter year)) {
        $duration   = "all";
    }

    my ($begindt,$enddt) = $self->get_begin_end($dt,$duration);

    my $match_ref   = {
        $timefield  => {
            '$and'  => [
                { '$gte'  =>  $begindt->epoch },
                { '$lte'  =>  $enddt->epoch },
            ],
        }
    };
    return $match_ref;
}

sub get_begin_end {
    my $self        = shift;
    my $dt          = shift;
    my $duration    = shift;
    my $sfunction   = "get_start_of_$duration";
    my $efunction   = "get_end_of_$duration";
    my $begindt     = $self->$sfunction($dt);
    my $enddt       = $self->$efunction($dt);
    return $begindt, $enddt;
}

sub get_start_of_day {
    my $self    = shift;
    my $dt      = shift;
    return DateTime->new(
        year    => $dt->year,
        month   => $dt->month,
        day     => $dt->day,
        hour    => 0,
        minute  => 0,
        second  => 0,
        time_zone    => $self->timezone,
    );
}

sub get_end_of_day {
    my $self    = shift;
    my $dt      = shift;
    my $enddt  = DateTime->new(
        year    => $dt->year,
        month   => $dt->month,
        day     => $dt->day,
        hour    => 23,
        minute  => 59,
        second  => 59,
        time_zone    => $self->timezone,
    );
    return $enddt;
}

sub get_start_of_month {
    my $self    = shift;
    my $dt      = shift;
    return DateTime->new(
        year    => $dt->year,
        month   => $dt->month,
        day     => 1,
        hour    => 0,
        minute  => 0,
        second  => 0,
        time_zone    => $self->timezone,
    );
}

sub get_end_of_month {
    my $self    = shift;
    my $dt      = shift;
    my $enddt  = DateTime->last_day_of_month(
        year    => $dt->year,
        month   => $dt->month,
        hour    => 23,
        minute  => 59,
        second  => 59,
        time_zone    => $self->timezone,
    );
    return $enddt;
}

sub get_start_of_year {
    my $self    = shift;
    my $dt      = shift;
    return DateTime->new(
        year    => $dt->year,
        month   => 1,
        day     => 1,
        hour    => 0,
        minute  => 0,
        second  => 0,
        time_zone    => $self->timezone,
    );
}

sub get_end_of_year {
    my $self    = shift;
    my $dt      = shift;
    my $enddt  = DateTime->last_day_of_month(
        year    => $dt->year,
        month   => 12,
        day     => 31,
        hour    => 23,
        minute  => 59,
        second  => 59,
        time_zone    => $self->timezone,
    );
    return $enddt;
}

sub get_start_of_quarter {
    my $self    = shift;
    my $dt      = shift;
    my $month   = $dt->month;
    my $qmonth  = $self->get_quarter_start_month($month);

    return DateTime->new(
        year    => $dt->year,
        month   => $qmonth,
        day     => 1,
        hour    => 0,
        minute  => 0,
        second  => 0,
        time_zone    => $self->timezone,
    );
}

sub get_end_of_quarter {
    my $self    = shift;
    my $dt      = shift;
    my $month   = $dt->month;
    my $qmonth  = $self->get_quarter_end_month($month);

    return DateTime->last_day_of_month(
        year    => $dt->year,
        month   => $qmonth,
        hour    => 23,
        minute  => 59,
        second  => 59,
        time_zone    => $self->timezone,
    );
}

sub get_sandia_quarter_from_dt {
    my $self    = shift;
    my $dt      = shift;

    if ( ! defined $dt ) {
        $dt = DateTime->now;
    }
    return $self->get_quarter_from_month($dt->month);
}

sub get_quarter_from_month {
    my $self    = shift;
    my $month   = shift;
    my %quarters    = (
        1   => 2,
        2   => 2,
        3   => 2,
        4   => 3,
        5   => 3,
        6   => 3,
        7   => 4,
        8   => 4,
        9   => 4,
        10  => 1,
        11  => 1,
        12  => 1,
    );
    return $quarters{$month};
}

sub get_quarter_start_month {
    my $self    = shift;
    my $quarter = shift;
    my %month   = (
        1       => 10,
        2       => 1,
        3       => 4,
        4       => 7,
    );
    return $month{$quarter};
}

sub get_quarter_end_month {
    my $self    = shift;
    my $quarter = shift;
    my %month   = (
        1       => 12,
        2       => 3,
        3       => 6,
        4       => 9,
    );
    return $month{$quarter};
}

sub get_sandia_fy_from_dt {
    my $self    = shift;
    my $dt      = shift;
    my $fy      = undef;

    if ( ! defined $dt ) {
        $dt = DateTime->now;
    }
    my $year    = $dt->year;
    my $month   = $dt->month;

    if ($month < 10 ) {
        $fy = $year;
    }
    else {
        $fy = $year + 1;
    }
    return $fy;
}

sub get_dt_from_sandia_fyq {
    my $self    = shift;
    my $type    = shift;
    my $fy      = shift;
    my $quarter = shift;
    my $tz      = $self->timezone;

    if ( $fy !~ /[fF2]*[yY0]*\d\d/ ) {
        return undef;
    }

    if ( $quarter !~ /[qQ]*[1234]/ ) {
        return undef;
    }

    $fy =~ m/[fF]*[yY]*(\d{2,4})/;
    my $numerical_fy = $1;
    if ( $numerical_fy < 1000 ) {
        $numerical_fy += 2000;
    }

    $quarter =~ m/[qQ]*([1234])/;
    my $numerical_quarter = $1;

    my $dt;

    if ($type eq "start") {
        $dt  = DateTime->new(
            year    => $numerical_fy,
            month   => $self->get_quarter_start_month($numerical_quarter),
            day     => 1,
            hour    => 0,
            minute  => 0,
            second  => 0,
            time_zone    => $self->timezone,
        );
    }
    else {
        $dt = DateTime->last_day_of_month(
            year    => $numerical_fy,
            month   => $self->get_quarter_end_month($numerical_quarter),
            hour    => 23,
            minute  => 59,
            second  => 59,
            time_zone    => $self->timezone,
        );
    }
    return $dt;
}

sub get_current_quarter {
    my $self    = shift;
    my $dt      = DateTime->now;
    my $month   = $dt->month;
    my $quarter = $self->get_quarter_from_month($month);
    return $quarter;
}

sub get_current_fy {
    my $self    = shift;
    my $dt      = DateTime->now;
    my $fy      = $self->get_sandia_fy_from_dt($dt);
    return $fy;
}



__PACKAGE__->meta->make_immutable;
1;
