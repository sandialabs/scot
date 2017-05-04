#!/usr/bin/env perl

use warnings;
use strict;
use v5.18;
use lib '../../lib';

use Data::Dumper;
use Test::More;
use Scot::Util::Date;

my $dateutil = Scot::Util::Date->new();

my $string1 = "2017-02-22 23:22:21";
my $dt      = $dateutil->parse_datetime_string($string1);

is($dt->year, 2017, "Correct Year");
is($dt->month, 2, "Correct Month");
is($dt->day, 22, "Correct Day");
is($dt->hour, 23, "Correct Hour");

my $testepoch = 1484956800;
no warnings 'redefine';
*DateTime::_core_time = sub { return $testepoch; };
# 1/21/2017 00:00:00
my $nowdt   = DateTime->now();
my @range = $dateutil->get_time_range({ range => "lifetime" });

is ($range[0]->epoch, 0, "Correct start time for lifetime");
is ($range[1]->epoch, $testepoch, "Correct start time for lifetime");

@range = $dateutil->get_time_range({ range => "now" });
is ($range[0]->minute, 0, "Correct starting minute for NOW");
is ($range[0]->hour, $nowdt->hour, "Correct Hour for NOW");
is ($range[0]->day, $nowdt->day, "Correct Day for NOW");
is ($range[0]->month, $nowdt->month, "Correct Month for NOW");
is ($range[0]->year, $nowdt->year, "Correct Year for NOW");
is ($range[1]->hour, $nowdt->hour, "Correct ending hour for Now");
is ($range[1]->minute, 59, "Correct ending minute for NOW");

@range = $dateutil->get_time_range({ range => "lasthour" });
my $lasthour = $nowdt->clone();
$lasthour->subtract(hours => 1);
is ($range[0]->minute,  0, "last hour start minute correct");
is ($range[0]->hour,  $lasthour->hour, "last hour start minute correct");
is ($range[0]->day,  $lasthour->day, "last hour start minute correct");
is ($range[0]->month,  $lasthour->month, "last hour start minute correct");
is ($range[0]->year,  $lasthour->year, "last hour start minute correct");
is ($range[1]->minute,  59, "last hour end minute correct");
is ($range[1]->hour,  $lasthour->hour, "last hour end minute correct");
is ($range[1]->day,  $lasthour->day, "last hour end minute correct");
is ($range[1]->month,  $lasthour->month, "last hour end minute correct");
is ($range[1]->year,  $lasthour->year, "last hour end minute correct");

@range = $dateutil->get_time_range({ range => 'today' });
my $today   = $nowdt->clone();
is ($range[0]->second,  0, "today start second correct");
is ($range[0]->minute,  0, "today start minute correct");
is ($range[0]->hour,  0, "today start minute correct");
is ($range[0]->day,  $today->day, "today start minute correct");
is ($range[0]->month,  $today->month, "today start minute correct");
is ($range[0]->year,  $today->year, "today start minute correct");
is ($range[1]->second,  59, "today end second correct");
is ($range[1]->minute,  59, "today end minute correct");
is ($range[1]->hour,  23, "today end minute correct");
is ($range[1]->day,  $today->day, "today end minute correct");
is ($range[1]->month,  $today->month, "today end minute correct");
is ($range[1]->year,  $today->year, "today end minute correct");

@range = $dateutil->get_time_range({ range => "yesterday" } );
my $yesterday   = $nowdt->clone();
$yesterday->subtract(days => 1);
is ($range[0]->second,  0, "yesterday start second correct");
is ($range[0]->minute,  0, "yesterday start minute correct");
is ($range[0]->hour,  0, "yesterday start minute correct");
is ($range[0]->day,  $yesterday->day, "yesterday start minute correct");
is ($range[0]->month,  $yesterday->month, "yesterday start minute correct");
is ($range[0]->year,  $yesterday->year, "yesterday start minute correct");
is ($range[1]->second,  59, "yesterday end second correct");
is ($range[1]->minute,  59, "yesterday end minute correct");
is ($range[1]->hour,  23, "yesterday end minute correct");
is ($range[1]->day,  $yesterday->day, "yesterday end minute correct");
is ($range[1]->month,  $yesterday->month, "yesterday end minute correct");
is ($range[1]->year,  $yesterday->year, "yesterday end minute correct");

@range = $dateutil->get_time_range({ range => "thismonth" });
my $month   = DateTime->last_day_of_month(
    year    => $nowdt->year, month => $nowdt->month,
    hour    => 23, minute => 59, second => 59);
is ($range[0]->second, 0, "this month start second correct");
is ($range[0]->minute, 0, "this month start second correct");
is ($range[0]->hour, 0, "this month start second correct");
is ($range[0]->day, 1, "this month start second correct");
is ($range[0]->month, $month->month, "this month start second correct");
is ($range[0]->year, $month->year, "this month start second correct");
is ($range[1]->second, 59, "this month end second correct");
is ($range[1]->minute, 59, "this month end second correct");
is ($range[1]->hour, 23, "this month end second correct");
is ($range[1]->day, $month->day, "this month end second correct");
is ($range[1]->month, $month->month, "this month end second correct");
is ($range[1]->year, $month->year, "this month end second correct");

@range = $dateutil->get_time_range({ range => "thisyear" });
my $year   = DateTime->new(
    year    => $nowdt->year, month => 1, day => 1,
    hour    => 0, minute => 0, second => 0);
is ($range[0]->second, 0, "this year start second correct");
is ($range[0]->minute, 0, "this year start minute correct");
is ($range[0]->hour, 0, "this year start hour correct");
is ($range[0]->day, 1, "this year start day correct");
is ($range[0]->month, 1, "this year start month correct");
is ($range[0]->year, $year->year, "this year start second correct");
is ($range[1]->second, 59, "this year end second correct");
is ($range[1]->minute, 59, "this year end minute correct");
is ($range[1]->hour, 23, "this year end hour correct");
is ($range[1]->day, 31, "this year end day correct");
is ($range[1]->month, 12, "this year end month correct");
is ($range[1]->year, $year->year, "this year end year correct");

@range = $dateutil->get_time_range({ range => "lastyear" });
   $year   = DateTime->new(
    year    => $nowdt->year - 1, month => 1, day => 1,
    hour    => 0, minute => 0, second => 0);
is ($range[0]->second, 0, "last year start second correct");
is ($range[0]->minute, 0, "last year start minute correct");
is ($range[0]->hour, 0, "last year start hour correct");
is ($range[0]->day, 1, "last year start day correct");
is ($range[0]->month, 1, "last year start month correct");
is ($range[0]->year, $year->year, "last year start year correct");
is ($range[1]->second, 59, "last year end second correct");
is ($range[1]->minute, 59, "last year end minute correct");
is ($range[1]->hour, 23, "last year end hour correct");
is ($range[1]->day, 31, "last year end day correct");
is ($range[1]->month, 12, "last year end month correct");
is ($range[1]->year, $year->year, "last year end year correct");

@range = $dateutil->get_time_range({ range => "thisquarter" });
my $quarter = $nowdt->clone();
my $qend    = $nowdt->clone();
$qend->add(months => 3);
$qend->truncate( to => "quarter");
$qend->subtract( seconds => 1 );
say Dumper($qend);

is ($range[0]->second, 0, "this quarter start second correct");
is ($range[0]->minute, 0, "this quarter start minute correct");
is ($range[0]->hour,   0, "this quarter start hour   correct");
is ($range[0]->day ,   1, "this quarter start day    correct");

is ($range[1]->second, 59, "this quarter start second correct");
is ($range[1]->minute, 59, "this quarter start minute correct");
is ($range[1]->hour,   23, "this quarter start hour   correct");
is ($range[1]->day ,   $qend->day, "this quarter start day    correct");

done_testing();
exit 0;
