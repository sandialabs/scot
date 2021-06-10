#!/usr/bin/env perl
use Data::Dumper;
# use Regexp::Debugger;
use feature qw(say);
my $splitre = qr{
    (
        [^\w<]+
        |
        [\s]+
        |
        \S+
    )
}xims;

my $text    = 'The quick brown fox jumped over the <adfadsf@foo.com> 10.10.10.1 12.12(.)12.12';

 my @words = ($text =~ m/$splitre/g);
#  my @words = split(/\s/, $text);

say Dumper(@words);
