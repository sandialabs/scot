#!/usr/bin/env perl

use lib '../../../../lib';
use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Scot::Email::Processor;

my $config = '../../../../../'.
             'Scot-Internal-Modules/etc/'.
             'test_email_processing.cfg.pl';
my $env = Scot::Env->new(
    config_file => $config,
);

ok(defined($env), "Scot::Env was created");

my $log = $env->log;

is(ref($log), "Log::Log4perl::Logger", "Logger created");


my $proc = Scot::Email::Processor->new({
    env => $env,
});

my @mailboxes = @{$proc->mailboxes()};

ok (scalar(@mailboxes) > 0, "Got at least one mailbox to check");


foreach my $mbox (@mailboxes) {

    print "Mailbox = \n".Dumper($mbox)."\n";
    my @messages = $proc->fetch_email($mbox);

    ok (scalar(@messages) > 0, "Got Some messges");
    print "Messages = \n".Dumper(\@messages)."\n";
}




done_testing();
