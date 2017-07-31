#!/usr/bin/env perl

use lib '../lib';
use Scot::Util::ScotClient;
use MIME::Base64;
use Data::Dumper;
use JSON;
use strict;
use warnings;
use v5.18;


my %users = (
    admin       => '61E4663E-6CAB-11E7-B011-FEE80D183886',
    joplin      => '51E4663E-6CAB-11E7-B011-FEE80D183886',
    kelly       => '41E4663E-6CAB-11E7-B011-FEE80D183886',
    montgomery  => '31E4663E-6CAB-11E7-B011-FEE80D183886',
    pilgrim     => '21E4663E-6CAB-11E7-B011-FEE80D183886',
);

my %clients = ();
foreach my $user (sort keys %users) {
    say "Initializing $user UA...";

    my $client  = Scot::Util::ScotClient->new({
        auth_type   => 'apikey',
        api_key => $users{$user},
        config  => {},
    });

    $clients{$user} = $client;
}

my @alerts  = &load_alerts;

foreach my $href (@alerts) {
    say "posting alert...";
    my $json    = $clients{'admin'}->post("alertgroup",$href);
    say Dumper($json);
    sleep 5;
}

my @events  = &load_events;

foreach my $href (@events) {
    my $user    = delete $href->{username};
    my $json    = $clients{$user}->post("event", $href);
    say Dumper($json);
    sleep 10;
}

my @intel   = &load_intel;
foreach my $href (@intel) {
    my $user    = delete $href->{username};
    my $json    = $clients{$user}->post("intel", $href);
    say Dumper($json);
    sleep 5;
}

my @entries = &load_entries;
foreach my $href (@entries) {
    my $user    = delete $href->{username};
    say "user = $user";
    my $json    = $clients{$user}->post("entry", $href);
    say Dumper($json);
    sleep 15;
}

my @promotions = &load_promotions;
foreach my $href (@promotions) {
    my $user        = delete $href->{username};
    my $promotee    = delete $href->{promotee};
    say "user = $user , promotee = $promotee";
    my $json    = $clients{$user}->put($promotee, { promote => "new" });
    say Dumper($json);
    sleep 5;
}

sub load_alerts {
    return (
        {
            source         => [ qw(email_examinr) ],
            subject         => "External HREF in Email",
            tag            => [qw(email href) ],
            groups          => {
                read        => [ qw(wg-scot-ir) ],
                modify      => [ qw(wg-scot-ir) ],
            },
            columns         => [ qw(MAIL_FROM MAIL_TO HREFS SUBJECT) ],
            data            => [
                {
                    MAIL_FROM   => "amlegit\@partner.net",
                    MAIL_TO     => "br549\@sandia.gov",
                    HREFS       => q{http://spmiller.org/news/please_read.html},
                    SUBJECT     => "Groundbreaking research!",
                },
                {
                    MAIL_FROM   => "scbrb\@aa.edu",
                    MAIL_TO     => "tbruner\@sandia.gov",
                    HREFS       => q{https://www.aa.edu/athletics/schedule},
                    SUBJECT     => "Schedule for next week",
                },
                {
                    MAIL_FROM   => "bubba\@bbn.com",
                    MAIL_TO     => "fmilszx\@sandia.gov",
                    HREFS       => "https://youtu.be/JAUoeqvedMo",
                    SUBJECT     => "Can not wait!",
                }
            ],
        },
        {
            source         => [ qw(inject_detect) ],
            subject         => "SQL Injection Attempts",
            tag            => [qw(sql href) ],
            groups          => {
                read        => [ qw(wg-scot-ir) ],
                modify      => [ qw(wg-scot-ir) ],
            },
            columns         => [ qw(src status_code method hostname uri referer content_disposition length) ],
            data            => [
                {
                    src		=> "50.203.149.4",
                    status_code	=> 500,
                    method		=> "GET",
                    hostname	=> "sittingduck.sandia.gov",
                    uri		=> q{/lookup.php?q=y;insert from users username="foo" },
                    referer		=> "http://www.osito.org/create_an_injection.html",
                    content_disposition	=> "text/plain",
                    length		=> "0",
                },
                {
                    src		=> "50.203.149.4",
                    status_code	=> 200,
                    method		=> "GET",
                    hostname	=> "sittingduck.sandia.gov",
                    uri		=> q{/lookup.php?q=y;insert into users username="foo" },
                    referer		=> "http://www.osito.org/create_an_injection.html",
                    content_disposition	=> "text/plain",
                    length		=> "346",
                },
            ],
        },
        {
            source         => [ qw(host_watchr) ],
            subject         => "Unusual Application Execution",
            tag            => [ qw(email href) ],
            groups          => {
                read        => [ qw(wg-scot-ir) ],
                modify      => [ qw(wg-scot-ir) ],
            },
            columns         => [ qw(APP_NAME PATH DESCRIPTION CHECKSUM USER TIMESTAMP) ],
            data            => [
                {
                    APP_NAME    => "kittens.scr",
                    PATH        => q{c:\users\jed\appdata\local\temp },
                    DESCRIPTION => "screensaver",
                    CHECKSUM    => "d41d8cd98f00b204e9800998ecf8427e",
                    USER	    => "jed",
                    TIMESTAMP   => 13072469257554,
                },
                {
                    APP_NAME    => "foobar.exe",
                    PATH        => q{c:\users\fred\appdata\local\temp },
                    DESCRIPTION => "exe",
                    CHECKSUM    => "a2506232cb3a3f1d9a2795c92f2bd5fd",
                    USER	    => "administrator",
                    TIMESTAMP   => 13072469257999,
                },
            ],
        },
        {
            source		=> [ qw(netdetctr) ],
            subject		=> "Executable downloaded",
            tag		=> [ qw(web executable) ],
            groups          => {
                read        => [ qw(wg-scot-ir) ],
                modify      => [ qw(wg-scot-ir) ],
            },
            columns     => [ qw(URL date dstip) ],
            data		=> [
                {
                    URL	=> 'http://bnet.downlow.com/dl?file=xplt.exe',
                    date	=> '2015-04-21 09:45:00',
                    dstip	=> '10.234.21.2',
                },
                {
                    URL	=> 'http://dark.foo.net/dl?file=stg2.exe',
                    date	=> '2015-04-21 09:47:00',
                    dstip	=> '10.234.21.2',
                },
                {
                    URL	=> 'http://chrome.google.com/download',
                    date	=> '2015-04-21 10:30:01',
                    dstip	=> '10.233.26.1',
                    file    => 'chromedownload.exe',
                },
                {
                    URL	=> 'http://openme.com/download',
                    date	=> '2015-04-21 10:29:04',
                    dstip	=> '10.233.26.1',
                    file    => 'openme.exe',
                },
            ],
        },
    );
}

sub load_events {
    return (
        {
            username        => 'joplin',
            source         => [ qw(email_examinr) ],
            subject         => "Bad External HREF in email",
            tag            => [qw(email href) ],
            groups          => {
                read        => [ qw(wg-scot-ir) ],
                modify      => [ qw(wg-scot-ir) ],
            },
        },
        {
            username        => 'montgomery',
            source         => [ qw(internal_scanner) ],
            subject         => "Unsuccessful attempts to access admin account",
            tag            => [qw(scanner password) ],
            groups          => {
                read        => [ qw(wg-scot-ir) ],
                modify      => [ qw(wg-scot-ir) ],
            },
        },
        {
            username        => 'pilgrim',
            source         => [ qw(lateral_movement) ],
            subject         => "Lateral Movement Detected",
            tag            => [qw(movement) ],
            groups          => {
                read        => [ qw(wg-scot-ir) ],
                modify      => [ qw(wg-scot-ir) ],
            },
        },
        {
            username        => 'kelly',
            source         => [ qw(proxy) ],
            subject         => "Unauthorized Web Traffic",
            tag            => [qw(web) ],
            groups          => {
                read        => [ qw(wg-scot-ir) ],
                modify      => [ qw(wg-scot-ir) ],
            },
        },
        {
            username        => 'pilgrim',
            source         => [ qw(analyst) ],
            subject         => "Hunting and found a bad file",
            tag            => [qw(malware hunting) ],
            groups          => {
                read        => [ qw(wg-scot-ir) ],
                modify      => [ qw(wg-scot-ir) ],
            },
        },
    );
}

sub load_intel {
   return ( 
        {
            username        => 'montgomery',
            source         => [ qw(twitter) ],
            subject         => "Twitter feed reporting 0 day",
            tag            => [qw(0day) ],
            groups          => {
                read        => [ qw(wg-scot-ir) ],
                modify      => [ qw(wg-scot-ir) ],
            },
        },
        {
            username        => 'kelly',
            source         => [ qw(twitter) ],
            subject         => "Twitter feed reporting new malicious md5 dump",
            tag            => [qw(md5) ],
            groups          => {
                read        => [ qw(wg-scot-ir) ],
                modify      => [ qw(wg-scot-ir) ],
            },
        },
    );
}

sub load_entries {
    return (
        {
            username => 'pilgrim',
            body 		=> "<p>More content found here: www.purple.com www.mytestsite.com; Can someone look into this?</p>",
            target_id	=> 1,
            target_type	=> 'event',
            parent		=> 0,
        },
        {
            username => 'kelly',
            body 		=> "<p>I checked the logs and can see that the user did indeed go the www.mytestsite.com. User has been contacted, but this needs to be escalated to determine if the connection was blocked.</p>",
            target_id	=> 1,
            target_type	=> 'event',
        },
        {
            username => 'joplin',
            body 		=> "<p>The connection wasn't blocked. After further investigation I can see that it also went out to 1.2.3.4.</p>",
            target_id	=> 1,
            target_type	=> 'event',
        },
        {
            username    => "montgomery",
            body 		=> "<p>Domains Found: www.foo.com www.hackingfoo.com; IPs found: 8.8.8.8</p>",
            target_id	=> 2,
            target_type	=> 'event',
        },
        {
            username => 'montgomery',
            body 		=> "<p>The user involved was testuser1 and their IP at the time of the action was 192.168.1.2.</p>",
            target_id	=> 2,
            target_type	=> 'event',
        },
        {
            username => 'joplin',
            body 		=> "<p>Checked proxy logs and found the following IPs attempting to scan: 123.456.789.012. They were attempting to scan the entire subnet. Need to check logs to see if this was blocked.</p>",
            target_id	=> 3,
            target_type	=> 'event',
        }, 
        {
            username => 'pilgrim',
            body 		=> "<p>Domains Found: www.foo.com www.hackingfoo.com; IPs found: 123.456.789.012</p>",
            target_id	=> 4,
            target_type	=> 'event',
        },
        {
            username    => 'pilgrim',
            body 		=> "<p>New CVE's from https://twitter.com/CVEnew/ reported the following 0 day: CVE-2017-0378. Do we have a signature built that will detect this? Keep your eyes open for delivery mechanisms. Original file was being sent in an email with the file name: openme.exe</p>",
            target_id	=> 1,
            target_type	=> 'intel',
        },
        {
            username    => 'kelly',
            body 		=> "<p>MD5 dump containing a list of known bad hashes. <p>098f6bcd4621d373cade4e832627b4f6 8253053f2c9e565a136264e6f96aa57b 5a105e8b9d40e1329780d62ea2265d8a ad0234829205b9033196ba818f7a872b</p></p>",
            target_id	=> 2,
            target_type	=> 'intel',
        }, 
        {
            username    => 'joplin',
            body 		=> "<p>While scouring through pcap I stumbled across some interesting traffic that I followed down a rabbit hole. I noticed an odd file name. Have we seen this file before? Here's the MD5 8253053f2c9e565a136264e6f96aa57b</p>",
            target_id	=> 5,
            target_type	=> 'event',
        },
    );
}

sub load_promotions {
    return (
        {
            username    => 'pilgrim',
            promotee    => 'alert/6',
        },
        {
            username    => 'joplin',
            promotee    => 'alert/2',
        },
        {
            username    => 'kelly',
            promotee    => 'event/1',
        },
    );
}
