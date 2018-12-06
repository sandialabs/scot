#!/usr/bin/env perl

use lib '../lib';
use strict;
use warnings;
use v5.16;
use Mojo::DOM;
use Scot::Env;

=head1 NAME

reports.pl

=head1 DESCRIPTION

Perl program to 

do reports

=cut

=head1 SYNOPSIS

    $0 

=cut

use lib '../lib';

use File::Slurp;    # to read config file
use Data::Dumper;   
use DateTime;
use DateTime::Format::Strptime;
use Log::Log4perl;
use Getopt::Long qw(GetOptions);

my $now = DateTime->now;
my $lastday = DateTime->last_day_of_month(year=> $now->year, month=>$now->month);

$| = 1;

my $start   = "1/1/2010 00:00:00";
my $end     = $lastday->mdy('/') . " 23:59:59"; 
my $report  = 'pyramid';
my $list_reports    = undef;

GetOptions(
    'start=s'     => \$start,
    'end=s'       => \$end,
    'report=s'  => \$report,
    'list_reports'  => \$list_reports,
) or die <<EOF

Invalid Option!

    usage:  $0 
        [--start mm/dd/yyyy hh:mm:ss]    start calculations from this time
        [--end   mm/dd/yyyy hh:mm:ss]    end calculation from this time
        [--report xyz]                   do the xyz report
        [--list_reports]                 list available reports

EOF
;

=head1 PROGRAM ARGUMENTS

=over 4


=back

=cut

my $config_file = $ENV{'scot_reports_config_file'} // '/opt/scot/etc/scot.cfg.pl';

my $env  = Scot::Env->new(
    config_file => $config_file,
);

$env->log->debug("-----------------");
$env->log->debug(" $0 Begins");
$env->log->debug("-----------------");

my $mongo   = $env->mongo;

my $stptime = DateTime::Format::Strptime->new(
    pattern => '%m/%d/%Y %T',
    locale  => 'en_US',
    time_zone   => 'America/Denver',
    on_error    => 'croak',
);

my $startdt  = $stptime->parse_datetime($start);
my $enddt    = $stptime->parse_datetime($end);

unless (defined $startdt and defined $enddt ) {
    die "Could not parse datetimes\n";
}

print "SCOT Stats\n\n";
print "For period:\n";
print  "Start                    End\n";
printf "%17s        %17s\n", $start, $end;
printf "%17d        %17d\n", $startdt->epoch, $enddt->epoch;


if ($list_reports) {
    list_reports();
}

if ( $report eq "pyramid" ) {
    pyramid();
}
elsif ( $report eq "alerts_by_month" ) {
    alerts_by_month();
}
elsif ( $report eq "response_times" ) {
    response_times();
}
elsif ( $report eq "compare_days" ) {
    compare_days($startdt);
}
elsif ( $report eq "event_report" ) {
    event_report();
}


$env->log->debug("========= Finished $0 ==========");
exit 0;

sub list_reports {
    print "
pyramid             Print totals for Alerts Events and Incidents
alerts_by_month     Print the total alerts receive by month
response_times      Print the average response time for alerts by year and month
compare_days        print totals for the last for days of the week specified by                         the start parameter
event_report        Print the Event report
";
    exit 1;
}

sub pyramid {

    my $query   = {
        created => {
            '$gte'  => $start,
            '$lte'  => $end,
        }
    };
    
    print "\n------- Pyramid Report ---------\n";
    my $col = $env->mongo->collection('Alertgroup');
    my $cursor  = $col->find($query);
    my $alert_count = $cursor->count();

    $col    = $env->mongo->collection('Event');
    $cursor     = $col->find($query);
    my $event_count = $cursor->count();

    $cursor     = $env->mongo->collection('Incident')->find($query);
    my $incident_count  = $cursor->count();

    printf "%12d   Alerts\n", $alert_count;
    printf "%12d   Events\n", $event_count;
    printf "%12d   Incidents\n", $incident_count;

}

sub compare_days {
    my $dt          = shift;
    my $week        = 60*60*24*7; #seconds
    my $day         = 60*60*24; #seconds

    my $startdt = DateTime->new(
        month   => $dt->month,
        day     => $dt->day,
        year    => $dt->year,
        hour    => 0,
        minute  => 0,
        second => 0
    );
    my $enddt   = DateTime->new(
        month   => $dt->month,
        day     => $dt->day,
        year    => $dt->year,
        hour    => 23,
        minute  => 59,
        second => 59
    );

    my %totals;

    foreach my $weeks_ago (0..8) {
        my $start_epoch = $startdt->epoch - ($weeks_ago * $week);
        my $end_epoch   = $enddt->epoch - ($weeks_ago * $week);
        my $cursor      = $mongo->read_documents({
            collection  => "alertgroups",
            match_ref   => {
                '$and'  => [ 
                    { when  => { '$gte' => $start_epoch } },
                    { when  => { '$lte' => $end_epoch } },
                ],
            },
            sort_ref    => { alertgroup_id => 1 },
        });
        my $currentdt   = DateTime->from_epoch(epoch=>$start_epoch);
        my $ymd         = $currentdt->ymd('-');
        $totals{$ymd}   = $cursor->count;
        #print "$ymd has $totals{$ymd} alertgroups\n";
    }
    print "\n--------------- Alerts ------------\n";
    print "Date, Count\n";
    foreach my $date (sort keys %totals) {
        print "$date, ". $totals{$date} . "\n";
    }
}



sub alerts_by_month {
    my $counter = 0;
    my $cursor  = $mongo->read_documents({
        collection  => "alertgroups",
        match_ref   => {
            '$and'  => [
                { when   => { '$gte' => $startdt->epoch } },
                { when   => { '$lte' => $enddt->epoch } },
            ],
        },
        sort_ref    => { alertgroup_id => 1 },
    });
    my $total = $cursor->count;
    my %results;
    my @debug;
    my $flag    = undef;

    while ( my $alert = $cursor->next_raw ) {
        printf "%d of %d\r", $counter++, $total;
        my $dt      = DateTime->from_epoch( epoch => $alert->{when});
        my $month   = $dt->month;
        my $year    = $dt->year;

        #my $wdt    = DateTime->from_epoch( epoch => $alert->{when} );
        #my $cdt    = DateTime->from_epoch( epoch => $alert->{created} );
        #my $udt    = DateTime->from_epoch( epoch => $alert->{updated} );

        #if ( $month == 9 and $year = 2013 ) {
            #if ( $alert->{updated} < $alert->{created} or 
            #     $alert->{when} < $alert->{created} ) {
#
#                if ( $alert->{updated} <= $alert->{when} ) {
#                    # print "Alert ". $alert->{alert_id} . "updated field is earlier\n";
#                    $year    = $udt->year;
#                    $month   = $udt->month;
#                    $flag++;
#                }
#                else {
#                    # print "Alert ". $alert->{alert_id} . " when field is earlier\n";
#                    $year    = $wdt->year;
#                    $month   = $wdt->month;
#                    $flag++;
#                }
#            }

#            if ( $wdt->ymd ne $cdt->ymd ) {
        #        print   "Alert ".$alert->{alert_id}." when ".$wdt->ymd.
        #                " created ".$cdt->ymd."\n";
#            }
            # if ( $udt->ymd ne $cdt->ymd ) {
        #        print   "Alert ".$alert->{alert_id}." updt ".$udt->ymd.
        #                " created ".$cdt->ymd."\n";
#                $year   = $wdt->year;
#                $month  = $wdt->month;
#                $flag++;
#            }

        #} 

        #if ( $year == 2013 and $month == 9 ) {
        #    if ( $wdt->year != 2013 or $udt->year != 2013 
        #         or $wdt->month != 9 or $udt->month != 9 ) {
        #        alert_debug($alert, $wdt, $cdt, $udt);
        #    }
        #}

        $results{$year}{$month}++;
     
    }

    print "\n--------------- Alerts by Month ------------\n";
    print "Year    Month    Count\n";
    foreach my $y (sort {$a<=>$b} keys %results) {
        foreach my $m (sort {$a<=>$b} keys %{$results{$y}} ) {
            printf "%d/%d, %d\n", $m, $y, $results{$y}{$m};
        }
    }
}

sub alert_debug {
    my $alert  = shift;
    my $wdt     = shift;
    my $cdt     = shift;
    my $udt     = shift;

    printf  
        "Alert   : %s \n".
        "   when    : %s  -> %s\n".
        "   created : %s  -> %s\n".
        "   updated : %s  -> %s\n",
        $alert->{id}, 
        $alert->{when},    
        $wdt->ymd,
        $alert->{created}, 
        $cdt->ymd,
        $alert->{updated}, 
        $udt->ymd;
}

sub response_times {
    my %results; 
    my $collection = $mongo->collection('Alertgroup');
    my $cursor  = $collection->find({
        '$and'  => [
            { when   => { '$gte' => $startdt->epoch } },
            { when   => { '$lte' => $enddt->epoch } },
        ],
    });
    $cursor->sort({id => 1});

    while ( my $alert = $cursor->next ) {
        my $when    = $alert->when;
        my $dt      = DateTime->from_epoch( epoch => $when);
        $dt->set_time_zone('America/Denver');
        my $month   = $dt->month;
        my $year    = $dt->year;
        my $hour    = $dt->hour;
        my $day     = $dt->day_of_week;
        printf "Alert %d : ", $alert->id;
        if ( $day > 0 and $day < 6 ) {
            if ( $hour < 18 and $hour > 7 ) {
                print " $month $hour: ";
                my $first_view = get_earliest($alert);
                if ( $first_view ) {
                    my $delta = $first_view - $when;
                    printf " %d seconds\n", $delta;
                    if ( $delta > 0 ) {
                        $results{$year}{$month}{total_time} += $delta;
                        $results{$year}{$month}{count} += $alert->alert_count;
                    }
                }
            }
            print " After Hours...\n";
        }
        else {
            print " Skipping the weekend...\n";
        }
    }

    printf "%s, %s, %s, %s, %s\n",
            "month", "total_seconds", "number alerts", "avg(secs)","avg(minutes)";

    foreach my $y ( sort {$a<=>$b} keys %results ) {
        foreach my $m ( sort {$a<=>$b} keys %{$results{$y}} ) {
            my $count   = $results{$y}{$m}{count};
            my $total_time  = $results{$y}{$m}{total_time};
            my $avg = $total_time / $count;

            printf "%s/%s, %d, %d, %4.4f, %4.4f\n", 
                $m, $y, $total_time, $count, $avg, $avg/60;
        }
    }
}

sub get_earliest {
    my $alertgroup   = shift;
    my $href    = $alertgroup->view_history;
    my @times   =   sort { $a <=> $b}
                    grep { $_ == $_ }
                    map  { $href->{$_}->{when} }
                    keys %{$href};
    foreach my $t (@times) {
        return $t if ( $t != 0 );
    }
    return undef;
}

sub event_report {
    my $counter = 0;
    my $cursor  = $mongo->read_documents({
        collection  => "events",
        match_ref   => {
            '$and'  => [
                { when   => { '$gte' => $startdt->epoch } },
                { when   => { '$lte' => $enddt->epoch } },
            ],
        },
        sort_ref    => { event_id => 1 },
    });
    my $total = $cursor->count;

    my %results = ();
    while ( my $event   = $cursor->next ) {
        my $created_dt  = DateTime->from_epoch(epoch=>$event->created);
        my $entry_count = $event->entry_count;
        my $view_count  = $event->view_count;
        my $team_count  = scalar(keys %{$event->viewed_by});
        my $score       = $entry_count * ( $view_count/$team_count );
        $results{$created_dt->year}{$created_dt->month}{events}++; 
        $results{$created_dt->year}{$created_dt->month}{views} += $view_count; 
        $results{$created_dt->year}{$created_dt->month}{entries} += $entry_count; 
        $results{$created_dt->year}{$created_dt->month}{score} += $score; 
    }
    
    print "Events By Month\n";
    print "Date, Events, Views, Counts, Score\n";
    foreach my $y (sort keys %results) {
        foreach my $m (sort keys %{$results{$y}}) {

            printf "%d-%d, %d, %d, %d, %d\n",
                    $y,
                    $m,
                    $results{$y}{$m}{events},
                    $results{$y}{$m}{views},
                    $results{$y}{$m}{entries},
                    $results{$y}{$m}{score};
        }
    }
}
