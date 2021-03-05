#!/usr/bin/env perl

use lib '../../../../lib';
use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Scot::Email::Processor;

my $env = Scot::Env->new(
    config_file => '../../../../../Scot-Internal-Modules/etc/mailtest.cfg.pl'
);

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





