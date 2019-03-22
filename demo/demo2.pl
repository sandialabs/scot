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
        {
            user    => "montgomery",
            verb    => "post",
            endpt   => "intel", # 2
            next    => 1,
            data    => {
                source         => [ qw(internal) ],
                subject         => "Threat Actor: Foobar Gang",
                tag            => [qw(threat_actor) ],
                groups          => {
                    read        => [ qw(wg-scot-ir) ],
                    modify      => [ qw(wg-scot-ir) ],
                },
            },
        },
        {
            user    => "montgomery",
            verb    => "post",
            endpt   => "entry",
            next    => 1,
            data    => {
                summary => 1,
                body    => <<'EOF',
<table>
    <tr>
        <th>
        <img src="data:image/png;base64,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"></th>
        <td>Threat Card</td>
    <tr>
</table>
EOF
                target_id   => 5,
                target_type => "intel",
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
            endpt   => "entry",
            next    => 1,
            data    => {
                body    => <<'EOF',
<table>
	<tr>
		<th>Names</th>
	    <td>
			<ul>
				<li>Foo Bear (LoudLike)</li>
			   	<li>APT-45321 (waternose)</li>
				<li>Fawn Gale (LendMacro)</li>
			</ul>
		</td>
	</tr>
	<tr>
		<th>TTP</th>
		<td>
			<ul>
				<li>Spearfishing to deliver malware and gain access</li>
				<li>Spearfishing to fake password reset site</li>
				<li>Watering hole attacks via iFrame</li>
				<li>Lateral movement attempts begin soon after inital compromise</li>
				<li>Drupal OpenBangImg Attack</li>
			</ul>
		</td>
	</tr>
	<tr>
		<th>Tools and Vulnerabilities</th>
		<td>
			<ul>
				<li>OpenBangImg : (drupal exploit)
				<li>BambooFlame : (backdoor)</li>
				<li>GoodCatch   : (downloader)</li>
				<li>Newtrap     : (cred harvester)</li>
			</ul>
		</td>
	</tr>
	<tr>
		<th>Network/Host Artifacts</th>
		<td>
			<ul>
				<li>Autostart: %USERPROFILE%\Application Data\Microsoft\Internet Explorer\\Quick Launch\</li>
				<li>XOR encryption using 0x0c key</li>
				<li>successful get of obi_upload_image.php</li>
			</ul>
		</td>
	</tr>
	<tr>
		<th>Domains</th>
		<td>
			<ul>
				<li>foo.com</li>
				<li>boombaz.org</li>
			</ul>
		</td>
	</tr>
	<tr>
		<th>IP Addrs</th>
		<td>
			<ul>
				<li>192.192.16.0/24</li>
				<li>16.12.14.12</li>
			</ul>
		</td>
	</tr>
</table>
EOF
                target_id   => 5,
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
                source         => [ qw(spamilicious) ],
                subject         => "Spammy Email Detected",
                tag            => [ qw(email href) ],
                groups          => {
                    read        => [ qw(wg-scot-ir) ],
                    modify      => [ qw(wg-scot-ir) ],
                },
                columns         => [ qw(FROM TARGET SUBJECT EMBEDDED_LINKS) ],
                data            => [
                    {
						FROM	=> "surveys\@xfinity.com",
						TARGET	=> "scot\@scotdemo.com",
						SUBJECT	=> "5 Question Survey, win \$50 bucks!",
						EMBEDDED_LINKS	=> "http://xqeraq.boombaz.org/survey",
                    },
                    {
						FROM	=> "surveys\@xfinity.com",
						TARGET	=> "sydney\@scotdemo.com",
						SUBJECT	=> "5 Question Survey, win \$50 bucks!",
						EMBEDDED_LINKS	=> "http://xqeraq.boombaz.org/survey",
                    },
                    {
						FROM	=> "surveys\@xfinity.com",
						TARGET	=> "maddox\@scotdemo.com",
						SUBJECT	=> "5 Question Survey, win \$50 bucks!",
						EMBEDDED_LINKS	=> "http://xqeraq.boombaz.org/survey",
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
                source         => [ qw(wapmagic) ],
                subject         => "Suspicious Drupal Activity",
                tag            => [ qw(wap href) ],
                groups          => {
                    read        => [ qw(wg-scot-ir) ],
                    modify      => [ qw(wg-scot-ir) ],
                },
                columns         => [ qw(TIME SRC DST METHOD CODE BYTES URL) ],
                data            => [
                    {
						TIME	=> "Fri Jun  1 14:10:47 MDT 2018",
						SRC		=> "192.192.16.15",
						DST		=> "4.24.8.2",
						METHOD	=> "get",
						CODE	=> 200,
						BYTES	=> 1232435,
						URL		=> "http://adfa.foo.com/obi_upload_image.php",
                    },
                    {
						TIME	=> "Fri Jun  1 15:10:47 MDT 2018",
						SRC		=> "192.192.16.15",
						DST		=> "4.24.18.105",
						METHOD	=> "get",
						CODE	=> 400,
						BYTES	=> 0,
						URL		=> "http://adfa.foo.com/obi_upload_image.php",
                    },
                ],
            },
        },
    );
} 
