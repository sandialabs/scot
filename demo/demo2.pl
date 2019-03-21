#!/usr/bin/env perl

use lib '/opt/scot/lib';
use Scot::Util::ScotClient;
use Scot::Env;
use MIME::Base64;
use Data::Dumper;
use JSON;
use strict;
use warnings;
use v5.16;

my $env = Scot::Env->new({
    config_file => '/opt/scot/etc/scot.cfg.pl',
});

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
        servername => 'scotdemo.com',
        env         => $env,
        config  => {

       },
    });

    $clients{$user} = $client;
}

my @items = &load_demo_data;

foreach my $item (@items) {
    my $verb    = $item->{verb};
    my $endpt   = $item->{endpt};
    my $json    = $clients{$item->{user}}->$verb($endpt, $item->{data});
    say Dumper($json);
#    sleep $item->{next};
}


sub load_demo_data {
    return (
        {
            user    => "joplin",
            verb    => "post",
            endpt   => "intel", # 1
            next    => 1,
            data    => {
                source         => [ qw(mandiant) ],
                subject         => "Mandiant APT1 Report",
                tag            => [qw(threat_actor) ],
                groups          => {
                    read        => [ qw(wg-scot-ir) ],
                    modify      => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "joplin",
            verb    => "post",
            endpt   => "entry",
            next    => 1,
            data    => {
                body    => "FQDN's extracted from Mandiant Report:
                    advanbusiness.com aoldaily.com aolon1ine.com
                    applesoftupdate.com appspot.com arrowservice.net
                    attnpower.com aunewsonline.com avvmail.com
                    bigdepression.net bigish.net blackberrycluter.com
                    blackcake.net bluecoate.com booksonlineclub.com
                    bpyoyo.com businessconsults.net businessformars.com
                    busketball.com canadatvsite.com canoedaily.com
                    cccpan.com chileexe77.com cnndaily.com
                    cnndaily.net cnnnewsdaily.com cometoway.org
                    companyinfosite.com competrip.com comrepair.net
                    comtoway.com conferencesinfo.com copporationnews.com
                    cslisten.com datastorage01.org defenceonline.net
                    dnsweb.org doemarkennel.com downloadsite.me
                    e-cardsshop.com earthsolution.org firefoxupdata.com
                    freshreaders.net giftnews.org globalowa.com
                    gmailboxes.com hkcastte.com hugesoft.org
                    hvmetal.com idirectech.com ifexcel.com
                    infobusinessus.org infosupports.com issnbgkit.net
                    jjpopp.com jobsadvanced.com livemymsn.com
                    lksoftvc.net maltempata.com marsbrother.com
                    mcafeepaying.com mediaxsds.net microsoft-update-info.com
                    micyuisyahooapis.com msnhome.org myyahoonews.com
                    nationtour.net newsesport.com newsonet.net newsonlinesite.com
                    newspappers.org nirvanaol.com ns06.net nytimesnews.net
                    olmusic100.com onefastgame.net oplaymagzine.com pcclubddk.net
                    petrotdl.com phoenixtvus.com pop-musicsite.com progammerli.com
                    purpledaily.com regicsgf.net reutersnewsonline.com rssadvanced.org
                    safalife.com safety-update.com saltlakenews.org satellitebbs.com
                    searchforca.com shepmas.com skyswim.net softsolutionbox.net spmiller.org
                    sportreadok.net staycools.net symanteconline.net syscation.com
                    syscation.net tfxdccssl.net theagenews.com thehealthmood.net tibethome.org
                    todayusa.org ueopen.com usabbs.org usapappers.com
                    ushongkong.org usnewssite.com usnftc.org ustvb.com
                    uszzcs.com voiceofman.com webservicesupdate.com widewebsense.com
                    worthhummer.net yahoodaily.com youipcam.com ys168.com ",
                target_id   => 1,
                target_type => "intel",
                parent      => 0,
                groups      => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "admin",
            verb    => "post",
            endpt   => "alertgroup",
            next    => 10,
            data    => {
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
                        # alert 1
                        MAIL_FROM   => "amlegit\@partner.net",
                        MAIL_TO     => "br549\@sandia.gov",
                        HREFS       => q{http://spmiller.org/news/please_read.html},
                        SUBJECT     => "Groundbreaking research!",
                    },
                    {
                        # alert 2
                        MAIL_FROM   => "scbrb\@aa.edu",
                        MAIL_TO     => "tbruner\@sandia.gov",
                        HREFS       => q{https://www.aa.edu/athletics/schedule},
                        SUBJECT     => "Schedule for next week",
                    },
                    {
                        # alert 3
                        MAIL_FROM   => "bubba\@bbn.com",
                        MAIL_TO     => "fmilszx\@sandia.gov",
                        HREFS       => "https://youtu.be/JAUoeqvedMo",
                        SUBJECT     => "Can not wait!",
                    }
                ],
            },
        },
        {
            user    => "admin",
            verb    => "post",
            endpt   => "alertgroup",
            next    => 10,
            data    => {
                source  => [ qw(tamizar) ],
                subject => "Hancitor Header Summary",
                tag     => [ ],
                groups          => {
                    read        => [ qw(wg-scot-ir) ],
                    modify      => [ qw(wg-scot-ir) ],
                },
                columns => [qw( received Date Message-ID Date1 From X-Mailer MIME-Version To Subject Content-Type Content-Transfer-Encoding URLs)],
                data => [
                {
                    received    => "from adpm.com()",
                    Date        => "Tue, 04 Apr 2017 15:34:16 +0000 (UTC)",
                    'Message-ID'  => '<B1C16B5B.0C1FE6F7@adpm.com>',
                    Date1       => "Tue, 04 Apr 2017 11:36:35 -0400",
                    From        => 'ADP Billing <bill@adpm.com>',
                    'X-Mailer'  => "iPad Mail (13F69)",
                    'MIME-Version'  => 1,
                    To          => "[removed]",
                    Subject     => "Your monthly bill 267362 is available!",
                    'Content-Type'  => 'text/html; charset="utf-8"',
                    'Content-Transfer-Encoding' => '7bit',
                    URLs        => "hxxp://adp-monthly-billling.com/getnum.php?id=[base64 string]",
                },
                ],
            },
        },
        {
            user    => "admin",
            verb    => "post",
            endpt   => "alertgroup",
            next    => 10,
            data    => {
                source  => [ qw(tamizar) ],
                subject => "Hancitor OLEdump Summary",
                tag     => [ ],
                groups          => {
                    read        => [ qw(wg-scot-ir) ],
                    modify      => [ qw(wg-scot-ir) ],
                },
                columns => [qw( )],
                data => [
                    {
                        hour    => "1:00",
                        type    => "",
                        size    => 113,
                        object  => '\x01CompObj',
                        hash    => 'f0ee69b36245f758dc57e94c7c58ee53',
                    },
                    {
                        hour    => "2:00",
                        type    => "",
                        size    => 4096 ,
                        object  => '\x05DocumentSummaryInformation',
                        hash    => '00b0cbaf5f75cbf45b2ee3eb95cc9220',
                    },
                    {
                        hour    => "3:00",
                        type    => "",
                        size    => 4096 ,
                        object  => '\x05SummaryInformation',
                        hash    => '29e8f0cbf869084e9c877083df2bace3',
                    },
                    {
                        hour    => "4:00",
                        type    => "",
                        size    => 4096 ,
                        object  => '1Table',
                        hash    => 'a8f90b19b6777956453b4c3f460e6217',
                    },
                    {
                        hour    => "5:00",
                        type    => "",
                        size    => 59774,
                        object  => 'Data',
                        hash    => 'cc050731a567601b69c611337741ea92',
                    },
                    {
                        hour    => "6:00",
                        type    => "",
                        size    =>  435,
                        object  => 'Macros/PROJECT',
                        hash    => 'd9cc4f482ae8cd16ea666412c64398c1',
                    },
                    {
                        hour    => "7:00",
                        type    => "",
                        size    => 89 ,
                        object  => 'Macros/PROJECTwm',
                        hash    => '4da2633fa5e500aa299424513695bb2d',
                    },
                    {
                        hour    => "8:00",
                        type    => "M",
                        size    => 109480 ,
                        object  => 'Macros/VBA/Module1',
                        hash    => '3b63659e348b0d2b0dcbd5c4dbb6d85d',
                    },
                    {
                        hour    => "9:00",
                        type    => "M",
                        size    => 11185 ,
                        object  => 'Macros/VBA/Module2',
                        hash    => 'fc35bcf66f97c8cbd8dcacb593679d8a',
                    },
                    {
                        hour    => "10:00",
                        type    => "M",
                        size    => 1097 ,
                        object  => 'Macros/VBA/ThisDocument',
                        hash    => 'e150bbaa63be622f6c610b65b2d6a7fe',
                    },
                    {
                        hour    => "11::00",
                        type    => "",
                        size    => 13477 ,
                        object  => 'Macros/VBA/_VBA_PROJECT',
                        hash    => 'd9f55fd800a6ecb2cfda1ac0603830b5',
                    },
                    {
                        hour    => "12:00",
                        type    => "",
                        size    =>  1259,
                        object  => 'Macros/VBA/__SRP_0',
                        hash    => 'd54cbbe13d73e98cb33264c27069db6d',
                    },
                    {
                        hour    => "13:00",
                        type    => "",
                        size    =>  110,
                        object  => 'Macros/VBA/__SRP_1',
                        hash    => 'c04e0b5d8f9488de2eca6925561d5927',
                    },
                    {
                        hour    => "14:00",
                        type    => "",
                        size    => 192 ,
                        object  => 'Macros/VBA/__SRP_2',
                        hash    => '9166ffe277e601c5453ba2f2725c1588',
                    },
                    {
                        hour    => "15:00",
                        type    => "",
                        size    => 66 ,
                        object  => 'Macros/VBA/__SRP_3',
                        hash    => 'f30e28c27ce2ed144a7b526a3662addf',
                    },
                    {
                        hour    => "16:00",
                        type    => "",
                        size    => 593 ,
                        object  => 'Macros/VBA/dir',
                        hash    => '5f6cedeea9f6d67e70fda5c55197376e',
                    },
                    {
                        hour    => "17:00",
                        type    => "",
                        size    => 4148 ,
                        object  => 'WordDocument',
                        hash    => 'f0f925d42d8196907206fb4230e8406c',
                    },
                ],
            },
        },
        {
            user    => "admin",
            verb    => "post",
            endpt   => "alertgroup",
            next    => 10,
            data    => {
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
                        # alert 4
                        src        => "50.203.149.4",
                        status_code    => 500,
                        method        => "GET",
                        hostname    => "sittingduck.sandia.gov",
                        uri        => q{/lookup.php?q=y;insert from users username="foo" },
                        referer        => "http://www.osito.org/create_an_injection.html",
                        content_disposition    => "text/plain",
                        length        => "0",
                    },
                    {
                        # alert 5
                        src        => "50.203.149.4",
                        status_code    => 200,
                        method        => "GET",
                        hostname    => "sittingduck.sandia.gov",
                        uri        => q{/lookup.php?q=y;insert into users username="foo" },
                        referer        => "http://www.osito.org/create_an_injection.html",
                        content_disposition    => "text/plain",
                        length        => "346",
                    },
                ],
            },
        },
        {
            # gnerate event 1
            user    => "pilgrim",
            verb    => "put",
            endpt   => "alert/1",
            next    => 1,
            data    => { promote => "new" },
        },
        {
            # guide 1
            user    => "montgomery",
            verb    => "post",
            endpt   => "guide",
            next    => 1,
            data    => {
                subject => "Guide to External HREF in Email",
                applies_to  => [ 'External HREF in Email' ],
                entry       => [
                    {   body    => "This alert type is greated by the email_examinr process and extracts significant HREF from the email.  First look at the HREF and see if the flair as malicious.  If unseen, you might need to use external resources to verify.  Also consider the source and destination addresses."
                    },
                ],
            },
        },
        {
            # guide 2
            user    => "kelly",
            verb    => "post",
            endpt   => "guide",
            next    => 1,
            data    => {
                subject => "Guide to Unusual Application Execution",
                applies_to  => [ 'Unusual Application Execution' ],
                entry       => [
                    {   body    => "This alert type is greated by the host_watchr  process and alerts when executions from unusual directories occur on a windows system.  For items that do not flair, submit checksum hash to VT for indications of maliciousness",
                    },
                ],
            },
        },
        {
            # guide 3
            user    => "joplin",
            verb    => "post",
            endpt   => "guide",
            next    => 1,
            data    => {
                subject => "Guide to SQL Injection Attempts",
                applies_to  => [ 'SQL Injection Attempts' ],
                entry       => [
                    {   body    => "This alert type is greated by the inject_detect  process and alerts when potential sql injections occur on DMZ websites.  Look at return codes, if you see a 200, circle the wagons.  Consider blocking traffic from sites with repeated attempts.",
                    },
                ],
            },
        },
        {
            user    => "admin",
            verb    => "post",
            endpt   => "alertgroup",
            next    => 10,
            data    => {
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
                        # alert 6
                        APP_NAME    => "kittens.scr",
                        PATH        => q{c:\users\jed\appdata\local\temp },
                        DESCRIPTION => "screensaver",
                        CHECKSUM    => "d41d8cd98f00b204e9800998ecf8427e",
                        USER        => "jed",
                        TIMESTAMP   => 13072469257554,
                    },
                    {
                        # alert 7
                        APP_NAME    => "foobar.exe",
                        PATH        => q{c:\users\fred\appdata\local\temp },
                        DESCRIPTION => "exe",
                        CHECKSUM    => "a2506232cb3a3f1d9a2795c92f2bd5fd",
                        USER        => "administrator",
                        TIMESTAMP   => 13072469257999,
                    },
                ],
            },
        },
        {
            user    => "admin",
            verb    => "post",
            endpt   => "alertgroup",
            next    => 10,
            data    => {
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
                        # alert 8
                        src        => "50.203.149.4",
                        status_code    => 500,
                        method        => "GET",
                        hostname    => "sittingduck.sandia.gov",
                        uri        => q{/lookup.php?q=y;insert from users username="foo" },
                        referer        => "http://www.osito.org/create_an_injection.html",
                        content_disposition    => "text/plain",
                        length        => "0",
                    },
                    {
                        # alert 9
                        src        => "50.203.149.4",
                        status_code    => 200,
                        method        => "GET",
                        hostname    => "sittingduck.sandia.gov",
                        uri        => q{/lookup.php?q=y;insert into users username="foo" },
                        referer        => "http://www.osito.org/create_an_injection.html",
                        content_disposition    => "text/plain",
                        length        => "346",
                    },
                ],
            },
        },
        {
            # intel 1
            user    => "pilgrim",
            verb    => "post",
            endpt   => "intel",
            next    => 3,
            data    => {
                subject => "Malicious Screen Savers",
                source  => [ 'fitzgerald' ],
            },
        },
        {
            user    => "pilgrim",
            verb    => "post",
            endpt   => "entry",
            next    => 3,
            data    => {
                body    => "Got a heads up from a friend and CorCo.  They have been seeing users downloading malicious Screen savers.  Keep an Eye open for these.  He's promising me some MD5 hashes later.  I will add them ASAP.",
                target_id   => 2,
                target_type => "intel",
                parent      => 0,
                groups          => {
                    read        => [ qw(wg-scot-ir) ],
                    modify      => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "pilgrim",
            verb    => "post",
            endpt   => "entry",
            next    => 3,
            data    => {
                body    => "Here's the first one they found: d41d8cd98f00b204e9800998ecf8427e usually has filename of kittens.scr",
                target_id   => 2,
                target_type => "intel",
                parent      => 1,
                groups          => {
                    read        => [ qw(wg-scot-ir) ],
                    modify      => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "admin",
            verb    => "post",
            endpt   => "alertgroup",
            next    => 10,
            data    => {
                source        => [ qw(netdetctr) ],
                subject        => "Executable downloaded",
                tag        => [ qw(web executable) ],
                groups          => {
                    read        => [ qw(wg-scot-ir) ],
                    modify      => [ qw(wg-scot-ir) ],
                },
                columns     => [ qw(URL date dstip) ],
                data        => [
                    {
                        # alert 10
                        URL    => 'http://bnet.downlow.com/dl?file=xplt.exe',
                        date    => '2015-04-21 09:45:00',
                        dstip    => '10.234.21.2',
                    },
                    {
                        # alert 11
                        URL    => 'http://dark.foo.net/dl?file=stg2.exe',
                        date    => '2015-04-21 09:47:00',
                        dstip    => '10.234.21.2',
                    },
                    {
                        # alert 12
                        URL    => 'http://chrome.google.com/download',
                        date    => '2015-04-21 10:30:01',
                        dstip    => '10.233.26.1',
                        file    => 'chromedownload.exe',
                    },
                    {
                        # alert 13
                        URL    => 'http://openme.com/download',
                        date    => '2015-04-21 10:29:04',
                        dstip    => '10.233.26.1',
                        file    => 'openme.exe',
                    },
                ],
            },
        },
        {
            # event 2
            user    => "joplin",
            verb    => "put",
            endpt   => "alert/6",
            next    => 1,
            data    => { promote => "new" },
        },
        {
            user    => "pilgrim",
            verb    => "post",
            endpt   => "entry",
            next    => 5,
            data    => {
                body    => "Here's our first hit of intel 1.  (Thanks Fitz)  Anyway, I've pulled the screensaver from the user's system and will be submitting to the sandbox.",
                target_id   => 2,
                target_type => "event",
                parent      => 0,
                groups      => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "joplin",
            verb    => "post",
            endpt   => "entry",
            next    => 5,
            data    => {
                body    => "Check VT and the hash is reported as malicious",
                target_id   => 2,
                target_type => "event",
                parent      => 0,
                groups      => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "montgomery",
            verb    => "post",
            endpt   => "entry", #12
            next    => 2,
            data    => {
                body    => "I'll start reversing...",
                target_id   => 2,
                target_type => "event",
                parent      => 0,
                groups      => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "montgomery",
            verb    => "put",
            endpt   => "entry/12",
            next    => 5,
            data    => { make_task => 1},
        },
        {
            user    => "pilgrim",
            verb    => "post",
            endpt   => "entry",
            next    => 5,
            data    => {
                body    => "Fitz came through again, their team says the screen saver becons back to cc.evil.co .  We need to put in a blackhole for that domain",
                target_id   => 2,
                target_type => "event",
                parent      => 0,
                groups      => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "pilgrim",
            verb    => "put",
            endpt   => "entry/13",
            next    => 5,
            data    => { make_task => 1},
        },
        {
            user    => "kelly",
            verb    => "put",
            endpt   => "entry/13",
            next    => 5,
            data    => { take_task => 1 },
        },
        {
            user    => "kelly",
            verb    => "post",
            endpt   => "entry",
            next    => 5,
            data    => {
                body    => "Blackhole block is in place and confirmed",
                target_id   => 2,
                target_type => "event",
                parent      => 14,
                groups      => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "kelly",
            verb    => "put",
            endpt   => "entry/13",
            next    => 5,
            data    => { close_task => 1 },
        },
        {
            user    => "joplin",
            verb    => "post",
            endpt   => "intel", # 2
            next    => 1,
            data    => {
                source         => [ qw(twitter) ],
                subject         => "Twitter feed reporting 0 day",
                tag            => [qw(0day) ],
                groups          => {
                    read        => [ qw(wg-scot-ir) ],
                    modify      => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "joplin",
            verb    => "post",
            endpt   => "entry",
            next    => 5,
            data    => {
                body    => "<p>New CVE's from https://twitter.com/CVEnew/ reported the following 0 day: CVE-2017-0378. Do we have a signature built that will detect this? Keep your eyes open for delivery mechanisms. Original file was being sent in an email with the file name: openme.exe</p>",
                target_id   => 3,
                target_type => "intel",
                parent      => 0,
                groups      => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "kelly",
            verb    => "post",
            endpt   => "intel", # 3
            next    => 5,
            data    => {
                source         => [ qw(twitter) ],
                subject         => "Twitter feed reporting new malicious md5 dump",
                tag            => [qw(md5) ],
                groups          => {
                    read        => [ qw(wg-scot-ir) ],
                    modify      => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "kelly",
            verb    => "post",
            endpt   => "entry",
            next    => 5,
            data    => {
                body    => "<p>MD5 dump containing a list of known bad hashes. <p>098f6bcd4621d373cade4e832627b4f6 8253053f2c9e565a136264e6f96aa57b 5a105e8b9d40e1329780d62ea2265d8a ad0234829205b9033196ba818f7a872b</p></p>",
                target_id   => 4,
                target_type => "intel",
                parent      => 0,
                groups      => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },
        },

        {
            user    => "joplin",
            verb    => "post",
            endpt   => "event", # 3
            next    => 5,
            data    => {
                source  => [ qw(internal_threat_detectr) ],
                subject => "Unsuccessful attempts to access admin account",
                tag     => [qw(insider password)],
                groups      => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "joplin",
            verb    => "post",
            endpt   => "entry",
            next    => 2,
            data    => {
                body    => "Going to pull pcap on this one and review logs",
                target_id   => 3,
                target_type => "event",
                parent  => 0,
                groups  => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "joplin",
            verb    => "post",
            endpt   => "entry",
            next    => 2,
            data    => {
                body    => "<pre>0000     00 a0 a5 81 7d b1 00 23 9c 13 53 82 08 00 45 00    ....m..#..T...E.
                0010     00 40 00 00 40 00 3e 11 ba f2 ac 1d 99 34 ac 1e    .@..@.>......3..
                0020     92 4b 0b f8 cd 6a 00 2c 18 a3 03 b9 00 24 2c ef    .J...j.,.....$,.
                0030     7f 2e c0 ff f3 f8 b4 1c df 1d 8e 01 3d f4 12 10    ............=...
                0040     52 65 71 75 65 73 74 20 44 65 6e 69 65 64         Request.Denied</pre><p>Look unsucessful...</p>",
                target_id   => 3,
                target_type => "event",
                parent  => 0,
                groups  => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "joplin",
            verb    => "put",
            endpt   => "event",
            next    => 2,
            data    => { status => "closed" },
        },
        {
            user    => "kelly",
            verb    => "post",
            endpt   => "entry",
            next    => 2,
            data    => {
                body    => "Promoting this to incident due to user's repeated attempts.  Let's get corporate investigations looking into what is going on.",
                target_id   => 3,
                target_type => "event",
                parent  => 0,
                groups  => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "kelly",
            verb    => "post",
            endpt   => "entry",
            next    => 2,
            data    => {
                body    => "Submitted to corporate investigations",
                target_id   => 1,
                target_type => "incident",
                parent      => 0,
                groups  => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "kelly",
            verb    => "put",
            endpt   => "intel/1",
            data    => {
                occurred    => time() - 10000,
                discovered  => time() -  9000,
                reported    => time() -  6000,
            },
        },
        {
            # event 2
            user    => "kelly",
            verb    => "put",
            endpt   => "event/3",
            next    => 1,
            data    => { promote => "new" },
        },
        {
            user    => "montgomery",
            verb    => "post",
            endpt   => "entry",
            next    => 2,
            data    => {
                body    => qq{<h2>Proxy Log</h2><br><pre>
                192.100.153.102 - - [11/Apr/2017:21:24:53 +0000] "GET /spmiller.org/news/please_read.html HTTP/1.1" 200 6609 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36"
                192.100.153.102 - - [11/Apr/2017:21:24:53 +0000] "GET /icons/ubuntu-logo.png HTTP/1.1" 200 3681 "https://spmiller.org/news/please_read.html" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36"
                192.100.153.102 - - [11/Apr/2017:21:24:53 +0000] "GET /favicon.ico HTTP/1.1" 404 562 "https://smiller.com/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36"},
                target_id   => 1,
                target_type => "event",
                parent  => 0,
                groups  => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },

        },
        {
            user    => "pilgrim",
            verb    => "post",
            endpt   => "entry",
            next    => 2,
            data    => {
                body    => 'Looks like user actually typed this in the browser.  Notice how they mispelled the URI then got it right the next time!  Advanced persistent User!  Oh well, time to do a forensic imaging,',
                target_id   => 1,
                target_type => "event",
                parent  => 0,
                groups  => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },

        },
        {
            user    => "pilgrim",
            verb    => "post",
            endpt   => "entry",
            next    => 2,
            data    => {
                body    => 'spmiller.org domain is associated with APT1',
                target_id   => 95,
                target_type => "entity",
                parent  => 0,
                groups  => {
                    read    => [ qw(wg-scot-ir) ],
                    modify  => [ qw(wg-scot-ir) ],
                },
            },

        },
    );
} 
