#!/usr/bin/env perl

use Mojo::UserAgent;
use JSON;
use strict;
use warnings;

my $ua      = Mojo::UserAgent->new;
my $json    = JSON->new;

my $user    = "admin";
my $pass    = "admin";
my $host    = "scotdemo.com";
my $url     = "https://$host/scot/api/v2";
my $authurl = "https://$host/auth";

my $tx  = $ua->post( $authurl => form => { user => $user, pass => $pass } );

my $alerts  = [
    {
        sources         => [ qw(email_examinr) ],
        subject         => "External HREF in Email",
        tags            => [qw(email href) ],
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
        sources         => [ qw(inject_detect) ],
        subject         => "SQL Injection Attempts",
        tags            => [qw(sql href) ],
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
        sources         => [ qw(host_watchr) ],
        subject         => "Unusual Application Execution",
        tags            => [ qw(email href) ],
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
        sources		=> [ qw(netdetctr) ],
        subject		=> "Executable downloaded",
        tags		=> [ qw(web executable) ],
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
            },
        ],
    },
];

foreach my $a (@$alerts) {
    my $tx  = $ua->post($url."/alertgroup" => json => $a);
    if ( my $res = $tx->success ) {
        print $res->body;
    }
    else {
        my $err = $tx->error;
        print "$err->{code} : $err->{message}\n";
    }
    sleep 5;
}

exit 0;
sleep 20;

my $tx = $ua->put($url."/promote" => json => {
	thing 	=> "alert",
	id	=> [ 6 ],
});

my $event_id = $tx->res->json->{id};

sleep 2;

$tx = $ua->post($url."/entry" => json => {});
	
