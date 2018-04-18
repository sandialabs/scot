#!/usr/bin/env perl
use lib '../../lib/';
use Scot::Env;
use Data::Dumper;
use Scot::Parser::Sourcefire;
use v5.18;

my $string  = q|[1:90010192:2] "(SIL) Bad known IPs TCP traffic SCOT-3306" [Impact: Unknown] From "MrKrabs ESnet IDS Engine/MrKrabs" at Sat Dec 30 21:32:25 2017 UTC [Classification: Will send an alert to scort-alerts@sandia.gov] [Priority: 1] {udp} 173.192.141.126:21336->134.253.115.242:54868|;

my $regex   = qr{\[(?<sid>.*?)\] "(?<rule>.*?)" \[Impact: (?<impact>.*?)\] +From "(?<from>.*?)" at (?<when>.*?) +\[Classification: (?<class>.*?)\] \[Priority: (?<pri>.*?)\] \{(?<proto>.*?)\} (?<rest>.*) *};


print $string."\n";
$string =~ tr/\015//d;
$string =~ m/$regex/g;

print 
    "sid        = " . $+{sid}   . "\n".
    "rule       = " . $+{rule}  . "\n".
    "impact     = " . $+{impact}  . "\n".
    "from       = " . $+{from}  . "\n".
    "when       = " . $+{when}  . "\n".
    "class      = " . $+{class}  . "\n".
    "priority   = " . $+{pri}  . "\n".
    "proto      = " . $+{proto} . "\n".
    "rest       = " . $+{rest} . "\n";
    

my $env = Scot::Env->new({
    config  => "/opt/scot/etc/scot.test.cfg.pl",
});

my $parser  = Scot::Parser::Sourcefire->new({log=>$env->log});

my $msg = {
    subject => "**Auto Generated Email** -- Policy Event: High Criticaility Rule/CRITICAL ALERT EMAIL at Fri Sep  9 10:09:01 2001 UTC",
    message_id  => '97912b1606804ab88d83e7a54521ad61@xq09AMFFONT.watermelon.com',
    body_plain  => $string,
    body        => $string,
    data        => [],
    source      => [ qw(email sourcefile) ],
};

my $response = $parser->parse_message($msg);

say Dumper($response);

