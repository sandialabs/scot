#!/usr/bin/env perl

# use Regexp::Debugger;

my $string  = '<span class="t">nat-source-address=</span>"<span class="t"><span class="t a">2600</span>:<span class="t a">387</span>:<span class="t a">8</span>:<span class="t a">f</span>:0:0:0:<span class="t a">a5</span></span>';
my $re      = qr{
(?:
# Mixed
(?:
# Non-compressed
 (?:[A-F0-9]{1,4}:){6}
# Compressed with at most 6 colons
|(?=(?:[A-F0-9]{0,4}:){0,6}
    (?:[0-9]{1,3}\.){3}[0-9]{1,3}  # and 4 bytes
#    \Z])                            # and anchored
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
#    \Z)  # and anchored
)
# and at most 1 double colon
(([0-9A-F]{1,4}:){1,7}|:)((:[0-9A-F]{1,4}){1,7}|:)
# Compressed with 8 colons
|(?:[A-F0-9]{1,4}:){7}:|:(:[A-F0-9]{1,4}){7}
)
}xmis;

$string   =~ m/$re/;

my $pre = substr($string, 0, $-[0]);
my $mat = substr($string, $-[0], $+[0] - $-[0]);
my $po  = substr($string, $+[0]);

print "pre = $pre\n";
print "mat = $mat\n";
print "po  = $po\n";
