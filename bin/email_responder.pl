#!/usr/bin/env perl

# start a Scot::Email::Responder to watch a queue
# first argument is the responder type. eg: 
# to start Scot::Email::Responder::Dispatch the 
# first arg is "dispatch"

use strict;
use warnings;
use lib '../lib';
use Scot::Env;
use Module::Runtime qw(require_module);
use Try::Tiny;

my $config  = "/opt/scot/etc/email_processing.cfg.pl";
my $env     = Scot::Env->new(config_file => $confg);

my $resptype = $ARGV[0];

if ( ! defined $resptype ) {
    $env->log->logdie("Failed to provide command line argument 0: Responder type");
}

my $class   = "Scot::Email::Responder::$resptype";

try {
    require_module($class);
}
catch {
    $env->log->logdie("$_.  Failed to load Module $class! Ensure module name patched a responder in /opt/scot/lib/Scot/Email/Responder.");
};

my $responder = $class->new({env => $env});
$responder->run();
