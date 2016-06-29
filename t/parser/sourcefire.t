#!/usr/bin/env perl
use Data::Dumper;

my $string  = qq|[1:90020059:2] "(JIM) SCOT-5696 Traffic from/to suspicious IP" [Impact: Unknown Target] From "MrKrabs ESnet IDS Engine/MrKrabs" at Sat May 16 17:46:32 2015 UTC [Classification: Critical - Send alert to scot-alerts.sandia.gov] [Priority: 1] {icmp} 64.237.51.163->132.175.62.167^M
^M|;

my $regex   = qr{\[(?<sid>.*?)\] "(?<rule>.*?)" \[Impact: (?<impact>.*?)\] +From "(?<from>.*?)" at (?<when>.*?) +\[Classification: (?<class>.*?)\] \[Priority: (?<pri>.*?)\] {(?<proto>.*)} (?<rest>.*) *};

$string =~ s/[\n\r]/ /g;
$string =~ m/$regex/g;


print 
    "sid        = " . $+{sid}   . "\n".
    "rule       = " . $+{rule}  . "\n".
    "impact     = " . $+{impact}  . "\n".
    "from       = " . $+{from}  . "\n".
    "when       = " . $+{when}  . "\n".
    "class      = " . $+{class}  . "\n".
    "priority   = " . $+{priority}  . "\n".
    "proto      = " . $+{proto} . "\n".
    "rest       = " . $+{rest} . "\n";
    
