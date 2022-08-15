#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';

use Scot::Env;
use Scot::Email::Processor;

my $config      = "/opt/scot/etc/email_processing.cfg.pl";
my $env         = Scot::Env->new(config_file => $config);
my $processor   = Scot::Email::Processor->new({env => $env});

my $flag = $ARGV[0];

unless ($flag) {
    $processor->run();
}

if ( $flag eq "-d" ) {
    $processor->dump_messages()
}


