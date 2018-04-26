#!/usr/bin/env perl

use v5.18;

use Mail::Send;

my $msg = Mail::Send->new(Subject => "Test", To => 'tbruner@sandia.gov');
my $fh  = $msg->open;
print $fh "This is a test email";
close $fh;

