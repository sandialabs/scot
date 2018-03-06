package Scot::Util::Date;

use DateTime;
use DateTime::Format::Strptime;
use Moose;


sub parse_datetime_string {
    my $self        = shift;
    my $datestring  = shift;

    if ($datestring eq "earliest" or $datestring eq "0") {
        return DateTime->from_epoch( epoch => 0 );
    }

    if ( $datestring eq "latest" or $datestring eq "now") {
        return DateTime->now();
    }

    my @patterns    = (
        '%Y-%m-%d %H',
        '%Y-%m-%d',
    );

    foreach my $pattern (@patterns) {
        my $strp = DateTime::Format::Strptime->new(
            pattern => $pattern
        );
        my $dt = $strp->parse_datetime($datestring);
        if (defined $dt and ref($dt) eq "DateTime" ) {
            return $dt;
        }
    }
    return undef;
}

sub get_ymdh_match {
    my $self    = shift;
    my $dt      = shift;
    return {
        year    => $dt->year,
        month   => $dt->month,
        day     => $dt->day,
        hour    => $dt->hour,
    };
}

sub get_qy_match {
    my $self    = shift;
    my $dt      = shift;
    return {
        quarter => $dt->quarter,
        year    => $dt->year,
    };
}

sub get_dow_match {
    my $self    = shift;
    my $dt      = shift;
    return {
        dow     => $dt->dow,
    };
}

sub get_this_year {
    my $self    = shift;
    my $dt      = DateTime->now();
    return $dt->year;
}

sub get_time_range {
    my $self    = shift;
    my $req     = shift;
    my $targetdt= shift;
    my @range   = ();

    unless ($targetdt) {
        $targetdt = DateTime->now;
    }
    
    # types of time ranges:
    #   - lifetime => response time over life of data collection
    #   - now => this hour
    #   - lasthour
    #   - today or yesterday
    #   - range (YYYY-MM-DD to YYYY-MM-DD)
    #   - thisyear, lastyear
    #   - thismonth, lastmonth
    #   - thisquarter, lastquarter, thisquarterlastyear

    my $rvalue = $req->{range};

    if ( ref($rvalue) eq "ARRAY" ) {
        if ( ref($rvalue->[0]) eq "DateTime" ) {
            if ( ref($rvalue->[1]) eq "DateTime" ) {
                @range = ( $rvalue->[0], $rvalue->[1] );
            }
        }
    }

    if ( $rvalue eq "lifetime" ) {
        @range  = (
            $self->parse_datetime_string("earliest"),
            $self->parse_datetime_string("now"),
        );
    }
    if ( $rvalue eq "now" ) {
        my $sdt = $targetdt;
        $sdt->truncate(to => 'hour');
        my $edt = $sdt->clone();
        $edt->set(minute => 59, second => 59);
        @range = ( $sdt, $edt );
    }
    if ( $rvalue eq "lasthour" ) {
        my $sdt = $targetdt;
        $sdt->subtract(hours=>1);
        $sdt->truncate(to => 'hour');
        my $edt = $sdt->clone();
        $edt->set(minute => 59, second => 59);
        @range = ($sdt, $edt);
    }
    if ( $rvalue eq "today" ) {
        my $sdt = DateTime->today();
        my $edt = $sdt->clone();
        $edt->set(hour => 23, minute => 59, second => 59);
        @range = ( $sdt, $edt );
    }
    if ( $rvalue eq "yesterday" ) {
        my $sdt = DateTime->today;
        $sdt->subtract(days => 1);
        my $edt = $sdt->clone();
        $edt->set(hour => 23, minute => 59, second => 59);
        @range = ( $sdt, $edt );
    }
    if ( $rvalue eq "thisweek" ) {
        my $sdt = $targetdt;
        my $edt = $sdt->clone();
        $edt->subtract(days => 7);
        $edt->truncate(to => "day");
        @range = ( $sdt, $edt );
    }
    if ( $rvalue eq "lastweek" ) {
        my $sdt = $targetdt;
        $sdt->subtract(days => 7);
        my $edt = $sdt->clone();
        $edt->subtract(days => 7);
        @range = ( $sdt, $edt );
    }
    if ( $rvalue eq "thismonth" ) {
        my $sdt = $targetdt;
        $sdt->truncate(to => "month");
        my $edt = DateTime->last_day_of_month(
            year    => $sdt->year,
            month   => $sdt->month, 
            hour    => 23, minute => 59, second => 59);
        @range = ( $sdt, $edt );
    }
    if ( $rvalue eq "lastmonth" ) {
        my $sdt = $targetdt;
        $sdt->subtract(months => 1);
        $sdt->truncate(to => "month");
        my $edt = DateTime->last_day_of_month(
            year    => $sdt->year,
            month   => $sdt->month, 
            hour    => 23, minute => 59, second => 59);
        @range = ( $sdt, $edt );
    }
    if ( $rvalue eq "thisyear" ) {
        my $sdt = $targetdt;
        $sdt->truncate(to => "year");
        my $edt = $sdt->clone();
        $edt->set(month => 12, day => 31, hour => 23, minute => 59, second => 59);
        @range = ( $sdt, $edt );
    }
    if ( $rvalue eq "lastyear" ) {
        my $sdt = $targetdt;
        $sdt->subtract(years => 1);
        $sdt->truncate(to => "year");
        my $edt = $sdt->clone();
        $edt->set(month => 12, day => 31, hour => 23, minute => 59, second => 59);
        @range = ( $sdt, $edt );
    }
    if ( $rvalue eq "thisquarter" ) {
        my $sdt = $targetdt;
        $sdt->truncate( to => "quarter" );
        my $edt = $sdt->clone();
        $edt->add(months => 3);
        $edt->truncate( to => "quarter" );
        $edt->subtract(seconds => 1);
        @range = ( $sdt, $edt );
    }
    if ( $rvalue eq "lastquarter" ) {
        my $sdt = $targetdt;
        $sdt->subtract(months => 3);
        $sdt->truncate( to => "quarter" );
        my $edt = $sdt->clone();
        $edt->add(months => 3);
        $edt->truncate( to => "quarter" );
        $edt->subtract(seconds => 1);
        @range = ( $sdt, $edt );
    }
    if ( scalar(@range) < 2 ) {
        # two arbitrary datestrings
        my ($sds,$eds) = split(/,/,$req->{range});
        my $sdt = $self->parse_datetime_string($sds);
        my $edt = $self->parse_datetime_string($eds);
        @range = ( $sdt, $edt );
    }
    return wantarray ? @range : \@range;
}

1;
