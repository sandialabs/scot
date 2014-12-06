#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

use lib '../lib';
use JSON;
use File::Slurp;
use Data::Dumper;
use Log::Log4perl;
use Scot::Bot::Reputation;


my $config_file     = "../scot.conf";
my $config_contents = read_file($config_file);
my $json            = JSON->new->relaxed(1);
my $config_href     = $json->decode($config_contents);

Log::Log4perl::init($config_href->{quality}->{logging_config});

my $logger      = Log::Log4perl->get_logger();
my $start       = time();

$logger->debug("-==-=-=-=-==-=-=-=-=-==-=-===");
$logger->debug("$0 starts at $start");

my $reputationbot    = Scot::Bot::Reputation->new({ 
    config  => $config_href,
    'log'   => $logger,
});
print "about to run reputation bot\n";
my $statsref    = $reputationbot->run();
my $end         = time();
my $elapsed     = $end - $start;

$logger->debug("reputationbot  Results");
$logger->debug(Dumper($statsref));
$logger->debug("$0 ends at $end");
$logger->debug("$0 execution wall clock time $elapsed seconds");
exit 0;
