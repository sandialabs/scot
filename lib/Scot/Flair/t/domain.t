# use Regexp::Debugger;
my $re  = qr{
    (
        (
            (?=
                [a-z0-9-]{1,63}
                \.
            )
            (xn--)?
            [a-z0-9]+
            (-[a-z0-9]+)*
            \.
        )+
        (
            [a-z0-9-]{2,63}
        )
        (?<=[a-z])
    )
}xims;

my $re2 = qr{
    ((?!-))
    (xn--)?[a-z0-9][a-z0-9-_]{0,61}[a-z0-9]{0,1}
    \.
    (xn--)?
    ([a-z0-9\-]{1,61}|[a-z0-9-]{1,30}\.[a-z]{2,})
}xims;

my $re3  = qr {
    \b(
        (
            (?!-)
            [a-z0-9-]{1,63}
            (?<!-)
            \.
        )+
        [a-z]{2,}
    )\b
}xims;

my @strings     = (
     'http://www.google.com',
     'https://scot.sandia.gov/#/foo',
    'foo.bar.yahoo.com',
     'DirBuster-0.12',
    'xn-clapcibic1.xn--plaa',
    'foo.xn--p1ai',
    'DirBuster-0.12 (http://www.owasp.org/',
);

foreach my $s (@strings) {
    print "$s\n";
    if ( $s =~ m/$re/ ) {
        print "!!! matches\n";
        my $pre     = substr($s, 0, $-[0]);
        my $match   = substr($s, $-[0], $+[0] - $-[0]);
        my $post    = substr($s, $+[0]);

        print "PRE   = $pre\n";
        print "MATCH = $match\n";
        print "POSt  = $post\n";
    }
    else {
        print "---- failed match ----\n";
    }
}

