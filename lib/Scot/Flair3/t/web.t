#!/usr/bin/env perl

use strict;
use warnings;
use lib '../../../../lib';

use Test::More;
use Test::Deep;
use Data::Dumper;
use Log::Log4perl;
use Scot::Flair3::Web;
use feature qw(say);


my $log = Log::Log4perl->get_logger('flair_test');
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
$log->level("TRACE");
$log->debug("web.t begins");
my $w = Scot::Flair3::Web->new();

my $uri = "https://thecyberpost.com/wp-content/plugins/cryptocurrency-price-ticker-widget/assets/coin-logos/tezos.svg";

my $dest = ".";

$w->get_image($uri, $dest);
