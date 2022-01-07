#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Scot::Flair3::Timer;
use Log::Log4perl;

my $t1  = get_timer("foo");
sleep 2;
print "t1 = ".&$t1." seconds\n";


my $log = Log::Log4perl->get_logger('timer_test');
my $pattern = "%d %7p [%P] %15F{1}: %4L %m%n";
my $layout  = Log::Log4perl::Layout::PatternLayout->new($pattern);
my $appender= Log::Log4perl::Appender->new(
    'Log::Log4perl::Appender::File',
    name        => 'flair_log',
    filename    => '/var/log/scot/test.log',
    autoflush   => 1,
    utf8        => 1,
);
$appender->layout($layout);
$log->add_appender($appender);
$log->level("DEBUG");


my $t2 = get_timer(undef, $log);
sleep 1;
&$t2;
