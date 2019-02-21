#!/usr/bin/env perl

use Regexp::Debugger;

#my $regex   = qr{
#    \b                                      # word boundary
#    (?<!\.)
#    (
#        # first 3 octets with optional [.],{.},(.) obsfucation
#        (?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\(*\[*\{*\.\)*\]*\}*){3}   
#        # last octet
#        (?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)
#        (/([0-9]|[1-2][0-9]|3[0-2]))   # the /32
#    )
#    \b
#}xims;

my $regex   = qr{
    \b                                      # word boundary
    (?<!\.)
    (
        # first 3 octets with optional [.],{.},(.) obsfucation
        (?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\(*\[*\{*\.\)*\]*\}*){3}   
        # last octet
        (?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)
    )
    (?!\.[0-9a-zA-Z])\b
    \b                                      # word boundary
}xims;

my $string = "10.126.188[.]212/2";

$string   =~ m/$regex/;

my $pre = substr($string, 0, $-[0]);
my $mat = substr($string, $-[0], $+[0] - $-[0]);
my $po  = substr($string, $+[0]);

print "pre = $pre\n";
print "mat = $mat\n";
print "po  = $po\n";
