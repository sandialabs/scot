#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

# use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
# use lib '/opt/scot/lib';
use Scot::App::Daily;
use Scot::Env;
use Data::Dumper;
use DateTime::Format::Strptime;

my $format = DateTime::Format::Strptime->new(
    pattern => '%Y%m%d',
    time_zone   => 'local',
    on_error    => 'croak',
);

say "--- Starting Daily Brief ---";

my $config_file = $ENV{'scot_app_alert_config_file'} // 
                    '../../Scot-Internal-Modules/etc/scot.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);



my $processor   = Scot::App::Daily->new({
    env => $env,
});

my $dateinput = $ARGV[0];
unless (defined $dateinput) {
    $processor->daily_briefing();
}
$processor->daily_briefing($format->parse_datetime($dateinput));
