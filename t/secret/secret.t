#!/usr/bin/env perl

use lib '../../lib';
use Scot::Secret;
use Test::More;

my $file    = "./sectest";
system("rm -f $file");

my $ss  = Scot::Secret->new(
    key     => 'foobar',
    file    => $file,
);

my $secret1 = "easy123";
$ss->add_secret("foo","bar", $secret1);

my $lines = $ss->secret_count;

is( $lines, 1, "added a secret");

my $pass = $ss->get_secret("foo","bar");

is ( $pass, $secret1, "got secret" );

my $secret2 = "abracadabra";
$ss->update_secret("foo","bar",$secret2);

$pass = $ss->get_secret("foo","bar");
is ( $pass, $secret2, "update of secret worked" );

$ss->add_secret("boom","baz","whatever");
$lines = $ss->secret_count;
is( $lines, 2, "added another secret");


$ss->delete_secret("foo","bar");
$lines = $ss->secret_count;
is( $lines, 1, "deleted a secret");




done_testing();
