#!/usr/bin/env perl

# use Regexp::Debugger;

my $regex   = qr{
    \b                                      # word boundary
    (
        (?=[a-z0-9-]{1,63}
        [\(\{\[]*\.[\]\}\)]*)               # optional obsfucation
        (xn--)?
        [a-z0-9]+
        (-[a-z0-9]+)*
        [\(\{\[]*\.[\]\}\)]*                # optional obsfucation
    )+
    (
        (xn--)?
        [a-z]{2,63}
    )
    \b                                      # word boundary
}xims;

# my $punystring = "xn-clapcibic1.xn--plaa";
my $punystring = "xn-clapcibic1.cn";

if ( $punystring =~ m/$regex/ ) {
    print "Match!!!\n";
}
