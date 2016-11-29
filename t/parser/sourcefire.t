#!/usr/bin/env perl
use lib '../../lib/';
use Data::Dumper;
use Scot::Util::Config;
use Scot::Util::Logger;
use Scot::Parser::Sourcefire;
use v5.18;

my $string  = qq|[1:90020059:2] "(JIM) SCOT-5696 Traffic from/to suspicious IP" [Impact: Unknown Target] From "MrKrabs ESnet IDS Engine/MrKrabs" at Sat May 16 17:46:32 2015 UTC [Classification: Critical - Send alert to scot-alerts.sandia.gov] [Priority: 1] {icmp} 64.237.51.163->10.10.20.167
|;

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
    


my $confobj = Scot::Util::Config->new({
    paths   => [ '../../../Scot-Internal-Modules', '/home/tbruner/Scot-Internal-Modules'],
    file    => 'logger_test.cfg',
});
my $loghref = $confobj->get_config();
my $log     = Scot::Util::Logger->new($loghref);
my $parser  = Scot::Parser::Sourcefire->new({log=>$log});

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

