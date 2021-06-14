#!/usr/bin/env perl

# use Regexp::Debugger;

# my $string  = 'BN6PR27MB2539.namprd13.prod.poutlook.org (2603:10b6:404:129::18)';
# my $string  = '(2603:10b6:404:129::18)';
# my $string  = '2603:10b6:404:129::18';
my @strings  = (
    '2001:489a:2202:2000:0000:0000:0000:0009:53',
    '1762:0:0:0:0:B03:1:AF18',
    '1762::b03:1:af18',
    'ip4:13.12.11[.]10',
);

my $re      = qr{
    \b
    # Suricata format ip:port
    (?:
        (?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}
    )(?=:[0-9]+)
	|(?:
        # Mixed
        (?:
            # Non-compressed
            |(?:[A-F0-9]{1,4}:){6}
            # Compressed with at most 6 colons
            |(?=(?:[A-F0-9]{0,4}:){0,6}
                (?:[0-9]{1,3}\.){3}[0-9]{1,3}  # and 4 bytes
                (?![:.\w])
            )
            # and at most 1 double colon
            (([0-9A-F]{1,4}:){0,5}|:)((:[0-9A-F]{1,4}){1,5}:|:)
            # Compressed with 7 colons and 5 numbers
            |::(?:[A-F0-9]{1,4}:){5}
        )
        # 255.255.255.
        (?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}
        # 255
        (?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])
        |# Standard
        (?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}
        |# Compressed with at most 7 colons
        (?=(?:[A-F0-9]{0,4}:){0,7}[A-F0-9]{0,4}
            (?![:.\w])
            )  # and anchored
        # and at most 1 double colon
        (([0-9A-F]{1,4}:){1,7}|:)((:[0-9A-F]{1,4}){1,7}|:)
        # Compressed with 8 colons
        |(?:[A-F0-9]{1,4}:){7}:|:(:[A-F0-9]{1,4}){7}
	)
    (?![:.\w]) # neg lookahead to "anchor"
}xmis;

foreach my $string (@strings) {
    $string   =~ m/$re/;

    my $pre = substr($string, 0, $-[0]);
    my $mat = substr($string, $-[0], $+[0] - $-[0]);
    my $po  = substr($string, $+[0]);

    print "pre = $pre\n";
    print "mat = $mat\n";
    print "po  = $po\n";
}
