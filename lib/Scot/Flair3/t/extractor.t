#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;

my $package = "Scot::Flair3::Extractor";
require_ok($package);

my $extractor   = Scot::Flair3::Extractor->new();

ok(defined $extractor, "Extractor initialized");
ok(ref($extractor) eq $package, "Extractor is type $package");

my $pds = $extractor->public_suffix;
ok(defined $pds, "public_suffix instantatiated");
ok(ref($pds) eq "Domain::PublicSuffix", "public_suffix is correct type");

my $deobs_test_data = {
    '10.10.10.1'    => [
        '10[.]10[.]10[.]1',
        '10{.}10{.}10{.}1',
        '10(.)10(.)10(.)1',
        '10[.]10(.)10{.}1',
        '10.10.10(.)1',
    ],
    'getscot.sandia.gov'    => [
        'getscot(.)sandia(.)gov',
        'getscot{.}sandia{.}gov',
        'getscot[.]sandia[.]gov',
        'getscot(.)sandia{.}gov',
        'getscot.sandia{.}gov',
    ],
};

foreach my $ipdom (keys %$deobs_test_data) {
    foreach my $value (@{$deobs_test_data->{$ipdom}}){
        ok( $ipdom eq $extractor->deobsfucate_ipdomain($value), 
            "$value correctly deobsfucated to $ipdom");
    }
}

my $testedb = {};
$extractor->add_entity($testedb, "foobar", "test");
ok ($testedb->{entities}->{test}->{foobar} == 1, "added entity");
$extractor->add_entity($testedb, "foobar", "test");
ok ($testedb->{entities}->{test}->{foobar} == 2, "incremented entity");
$extractor->add_entity($testedb, "Zoo", "test");
ok ($testedb->{entities}->{test}->{zoo} == 1, "lower cased entity");

my $target_span = '<span class="entity foo" data-entity-type="foo" data-entity-value="bar">bar</span>';
my $span    = $extractor->create_span("bar", "foo");
ok ($target_span eq $span->as_HTML, "created span correctly");

my $msgdata  = {
    '<ffffff@abcdabcd.com>' => {
        span    => $extractor->create_span('<ffffff@abcdabcd.com>', 'message_id'),
        edb     => { entities => { message_id => { '<ffffff@abcdabcd.com>' => 1 }}},
    },
    '&lt;ffffff@abcdabcd.com&gt;' => {
        span    => $extractor->create_span('<ffffff@abcdabcd.com>', 'message_id'),
        edb     => { entities => { message_id => { '<ffffff@abcdabcd.com>' => 2 }}},
    },
};

foreach my $t (keys %$msgdata) {
    my $tedb = {};
    my $span = $extractor->message_id_action($t, $tedb);
    my $shtml   = $span->as_HTML('');
    my $melem   = $msgdata->{$t}->{span};
    my $mhtml   = $melem->as_HTML('');
    ok ($shtml eq $mhtml, "Message id span correct $shtml ");
    ok ($tedb->{entities}->{message_id}->{'<ffffff@abcdabcd.com>'} == 1, "EDB correct");
}

my $emaildata   = {
        'tbruner@sandia.gov'    => {
            span    => '<span class="entity email" data-entity-type="email" data-entity-value="tbruner@sandia.gov">tbruner@<span class="entity domain" data-entity-type="domain" data-entity-value="sandia.gov">sandia.gov</span></span>',
            edb     => {
                entities => {
                    email   => { 'tbruner@sandia.gov' => 1 },
                    domain  => { 'sandia.gov' => 1 },
                }
            },
        },
    };

foreach my $em (keys %$emaildata) {
    my $tedb    = {};
    my $span    = $extractor->email_action($em, $tedb);
    my $gothtml = $span->as_HTML('');
    is ($gothtml, $emaildata->{$em}->{span}, "Email Spans correct");
    is ($tedb->{entities}->{email}->{'tbruner@sandia.gov'}, 1, "EDB email correct");
    is ($tedb->{entities}->{domain}->{'sandia.gov'}, 1, "EDB domain correct");
}

my $ipv6data = {
    '2607:f0d0:1002:51::4'  => {
        span    => '<span class="entity ipv6" data-entity-type="ipv6" data-entity-value="2607:f0d0:1002:51:0:0:0:4">2607:f0d0:1002:51:0:0:0:4</span>',
        edb     => {
            entities => {
                ipv6 => { '2607:f0d0:1002:51:0:0:0:4' => 1 }
            },
        },
    },
};

foreach my $i6 (keys %$ipv6data) {
    my $e       = {};
    my $span    = $extractor->ipv6_action($i6, $e);
    my $gothtml = $span->as_HTML('');
    is ($gothtml, $ipv6data->{$i6}->{span}, "ipv6 span correct");
    is ($e->{entities}->{ipv6}->{'2607:f0d0:1002:51:0:0:0:4'}, 1, "EDB correct");
}

my $ipdata  = {
    '10.10.10.1'    => {
        span    => '<span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span>',
        edb => {
            entities    => { ipaddr => { '10.10.10.1' => 1 } }
        },
    },
};

foreach my $i (keys %$ipdata) {
    my $e   = {};
    my $span    = $extractor->ipaddr_action($i, $e);
    my $html    = $span->as_HTML('');
    my $exp     = $ipdata->{$i}->{span};
    is($html, $exp, "Got expected IP span");
    is($e->{entities}->{ipaddr}->{$i}, 1, "EDB correct");
}

my $tedb    = {
    cache   => {
        domain_fp   => {
            'foo.com' => 1,
            'bar.com' => 1,
            'bzi.zip' => 1,
        }
    }
};
ok( $extractor->previous_false_positive_domain($tedb,'foo.com'), "Found prev FP domain");
ok( $extractor->previous_false_positive_domain($tedb,'bar.com'), "Found prev FP domain");
ok( $extractor->previous_false_positive_domain($tedb,'bzi.zip'), "Found prev FP domain");
ok(!$extractor->previous_false_positive_domain($tedb,"sandia.gov"), "Didnot find sandia.gov as a FP");

is( $extractor->get_root_domain('getscot.sandia.gov'), 'sandia.gov', "Got Root Domain for valid domain");
is( $extractor->get_root_domain('sandia.gov'), 'sandia.gov', "Handled Root Domain for valid domain");
is( $extractor->get_root_domain('adsfasd.adsfads.f'), undef, "Handled invalid domain");

my $dedb = {};
my $span1   = $extractor->domain_action('getscot.sandia.gov', $dedb);
my $span2   = $extractor->domain_action('dafasdf.adsf.f', $dedb);
is ($span1->as_HTML(''), '<span class="entity domain" data-entity-type="domain" data-entity-value="getscot.sandia.gov">getscot.sandia.gov</span>', "Span for valid domain correct");
is ($span2, undef, "Rejected invalid domain");
is ($dedb->{cache}->{domain_fp}->{'dafasdf.adsf.f'}, 1, "Domain false positive recorded in EDB");

$span1 = $extractor->post_match_actions("adsfasdfasdf", "foohash", $dedb);
is ($span1->as_HTML(''), '<span class="entity foohash" data-entity-type="foohash" data-entity-value="adsfasdfasdf">adsfasdfasdf</span>', "default post match action works");
is ($dedb->{entities}->{foohash}->{adsfasdfasdf}, 1, "default post match EDB works");

$dedb   = {};
my $data    = "The quick brown fox jumped over the lazy dog";
my $re      = qr{quick};
my $rt      = 'foo';

my $e_pre   = "The ";
my $e_match = '<span class="entity foo" data-entity-type="foo" data-entity-value="quick">quick</span>';
my $e_post  = " brown fox jumped over the lazy dog";

my ($g_pre, $g_match, $g_post) = $extractor->find_flairable($data, $re, $rt, $dedb);

is($g_pre, $e_pre, "find flairable pre matches");
is($g_match->as_HTML(''), $e_match, "find flairable match works");
is($g_post, $e_post, "find flairable post matches");
is($dedb->{entities}->{foo}->{quick}, 1, "EDB updated properly");

my $regexes = [ 
    { regex => qr{quick}, type => 'foo' },
    { regex => qr{lazy}, type => 'bar' },
    { regex => qr{good}, type => 'boom' },
];

$dedb   = {};
$data .= " and a good time was had by all";
my @got = $extractor->parse($regexes, $dedb, $data);
is ($got[0], "The ", "Parse element 0 correct");
is ($got[1]->as_HTML(''), '<span class="entity foo" data-entity-type="foo" data-entity-value="quick">quick</span>', "Parse element 1 correct");
is ($got[2], " brown fox jumped over the ", "Parse element 2 correct");
is ($got[3]->as_HTML(''), '<span class="entity bar" data-entity-type="bar" data-entity-value="lazy">lazy</span>', "Parse element 3 correct");
is ($got[4], " dog and a ", "Parse element 4 correct");
is ($got[5]->as_HTML(''), '<span class="entity boom" data-entity-type="boom" data-entity-value="good">good</span>', "Parse element 5 correct");
is ($got[6], " time was had by all", "Parse element 6 correct");



done_testing();
exit 0;
