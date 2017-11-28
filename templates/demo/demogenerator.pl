#!/usr/bin/env perl

use Mojo::UserAgent;
use JSON;
use strict;
use warnings;

my %users = (
    admin       => 'apikey 61E4663E-6CAB-11E7-B011-FEE80D183886',
    joplin      => 'apikey 51E4663E-6CAB-11E7-B011-FEE80D183886',
    kelly       => 'apikey 41E4663E-6CAB-11E7-B011-FEE80D183886',
    montgomery  => 'apikey 31E4663E-6CAB-11E7-B011-FEE80D183886',
    pilgrim     => 'apikey 21E4663E-6CAB-11E7-B011-FEE80D183886',
);

my %ua  = ();

foreach my $user (keys %users) {
    $ua{$user}  = Mojo::UserAgent->new;
    $ua{$user}->on(
        start   => sub {
            my $agent  = shift;
            my $tx     = shift;
            $tx->req->headers->header(
                'Authorization' => $users{$user},
                'Host'          => 'localhost',
            );
        }
    );
}


my $json    = JSON->new;

my $host    = "scotdemo.com";
my $url     = "https://$host/scot/api/v2";
my $authurl = "https://$host/auth";

my $alerts  = [
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
];

my $events  = [
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
];

my $intel  = [
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
        username        => 'kelley',
        source         => [ qw(twitter) ],
        subject         => "Twitter feed reporting new malicious md5 dump",
        tag            => [qw(md5) ],
        groups          => {
            read        => [ qw(wg-scot-ir) ],
            modify      => [ qw(wg-scot-ir) ],
        },
    },
];

my $entries = [
    {
        username => 'pilgrim',
	body 		=> "<p>More content found here: www.purple.com www.mytestsite.com; Can someone look into this?</p>",
	target_id	=> 1,
	target_type	=> 'event',
	parent		=> 0,

    },
    {
        username => 'kelley',
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
        username    => 'kelley',
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
];


#Add Alertgroups
foreach my $a (@$alerts) {
    my $tx  = $ua{admin}->post($url."/alertgroup" => json => $a);
    if ( my $res = $tx->success ) {
        print $res->body;
    }
    else {
        my $err = $tx->error;
        print "$err->{code} : $err->{message}\n";
    }
    sleep 5;
}


#Add Events
foreach my $a (@$events) {
    my $username = delete $a->{username};
    my $agent  = $ua{$username};
    my $tx  = $agent->post($url."/event" => json => $a);
    if ( my $res = $tx->success ) {
        print $res->body;
    }
    else {
        my $err = $tx->error;
        print "$err->{code} : $err->{message}\n";
    }
    sleep 5;
}

#Add Intel
foreach my $a (@$intel) {
    my $username = delete $a->{username};
    my $agent  = $ua{$username};
    my $tx  = $agent->post($url."/intel" => json => $a);
    if ( my $res = $tx->success ) {
        print $res->body;
    }
    else {
        my $err = $tx->error;
        print "$err->{code} : $err->{message}\n";
    }
    sleep 5;
}

#Add Entries
foreach my $a (@$entries) { 
    my $username = delete $a->{username};
    my $agent  = $ua{$username};
    my $tx = $agent->post($url."/entry" => json => $a);
    if ( my $res = $tx->success) {
        print $res->body;
    }
    else {
        my $err = $tx->error;
        print "$err->{code} : $err->{message}\n";
    }
    sleep 5;
}

#Promote alerts
my $tx = $ua{'pilgrim'}->put($url."/alert/6" => json => {
	promote => "new",
});

sleep 5;

$tx = $ua{'joplin'}->put($url."/alert/2" => json => {
	promote => "new",
});

sleep 5;

#Promote Events
$tx = $ua{'kelley'}->put($url."/event/1" => json => {
	promote => "new",
});

#my $event_id = $tx->res->json->{id};

sleep 2;

$tx = $ua{'pilgrim'}->post($url."/entry" => json => {});
	
exit 0;
sleep 20;
