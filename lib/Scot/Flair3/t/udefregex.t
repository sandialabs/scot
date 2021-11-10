#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Log::Log4perl;
use Scot::Env;
use Meerkat;


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

my $mongo   = Meerkat->new(
    model_namespace         => 'Scot::Model',
    collection_namespace    => 'Scot::Collection',
    database_name           => 'scot-test',
    client_options          => {
        host        => 'mongodb://localhost',
        w           => 1,
        find_master => 1,
        socket_timeout_ms => 600000,
    }
);

my $queue   = "/queue/flairtest";
my $topic   = "/topic/scottest";

my $iopackage   = "Scot::Flair3::Io";
require_ok($iopackage);
my $io  = Scot::Flair3::Io->new(
    log     => $log,
    mongo   => $mongo,
    queue   => $queue,
    topic   => $topic,
);
ok(defined $io, "io initialized");

my $env = Scot::Env->new({config_file => './test.cfg.pl'});

my $package = "Scot::Flair3::UdefRegex";
require_ok($package);
my $r = Scot::Flair3::UdefRegex->new(io => $io);

my $set = $r->regex_set;

print Dumper($set);
