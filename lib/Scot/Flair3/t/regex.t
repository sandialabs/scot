#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;

require_ok("Scot::Flair3::Regex");
my $re  = Scot::Flair3::Regex->new();
ok(defined $re, "Regex created");
is(ref($re), "Scot::Flair3::Regex", "correct type");

my $uuid1   = $re->regex_uuid1;
is (ref($uuid1), "HASH", "got uuid hash");

my @uuids   = (qw(
    7db416dc-1fa0-11ec-8431-9f6fecde6ba3
    b7f0d0f3-1fa2-11ec-a607-112a2d19cc91
));

foreach my $u (@uuids) {
    my $r = $uuid1->{regex};

    ok($u =~ /$r/, "$u matched");
}

done_testing();
exit 0;

