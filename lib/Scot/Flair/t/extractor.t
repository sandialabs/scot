#!/usr/bin/env perl

use strict;
use warnings;
use lib '../../../../lib';
use lib '.';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use TestSamples;
use HTML::Element;
use feature qw(say);

my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new({config_file => $config_file});
my $timer       = $env->get_timer("All Test Completed");

ok (defined $env, "Environment defined");
ok (ref($env) eq "Scot::Env", "It is a Scot::Env");

require_ok('Scot::Flair::Regex');
my $regex = Scot::Flair::Regex->new({env => $env});

require_ok('Scot::Flair::Extractor');
my $extractor = Scot::Flair::Extractor->new(env => $env, scot_regex => $regex);

ok(defined $extractor, "extractor module instantiated");

test_external_defined_entity_class();
test_is_not_leaf_node();
test_add_entity();
test_ipaddr_action();
test_email_action();
test_samples();
&$timer;
done_testing();

sub test_samples {
    my @samples    = ();
    push @samples, @TestSamples::ipv4_examples;
    push @samples, @TestSamples::email_tests;
    push @samples, @TestSamples::cve_tests;
    push @samples, @TestSamples::laika_tests;
    push @samples, @TestSamples::cidr_tests;
    push @samples, @TestSamples::file_tests;
    push @samples, @TestSamples::ipv6_tests;
    push @samples, @TestSamples::uuid1_tests;
    push @samples, @TestSamples::messageid_tests;
    push @samples, @TestSamples::clsid_tests;
    

    foreach my $sample (@samples) {
        my $testname = $sample->{name};
        my $html     = $sample->{source};
        my $flair    = $sample->{flair};
        my $edb      = $sample->{entities};
        my $text     = $sample->{plain};
        chomp($text);
        chomp($flair);
        my $got   = $extractor->process_html($html);

        chomp($got->{flair});
        chomp($got->{text});

        is( $got->{flair}, $flair, "$testname flair correct") or myfail($got->{flair}, $flair);
        is ( $got->{text}, $text, "$testname plain text") or myfail($got->{text}, $text);
        cmp_deeply($got->{entities}, $edb, "$testname") or done_testing, exit;
    }
}

sub myfail {
    my $g = shift;
    my $e = shift;
    print "Got: ====x=========x=========x\n$g\n";
    print "Exp: ====x=========x=========x\n$e\n";
    done_testing();
    exit;
}

sub test_external_defined_entity_class {
    my $good_test_element = HTML::Element->new('span',
        'class' => 'userdef',
        'data-entity-type'  => 'boombaz',
        'data-entity-value' => 'foobar'
    );
    my $bad_test_element = HTML::Element->new('span',
        'class' => 'nothingspecial',
        'data-entity-type'  => 'foo',
        'data-entity-value' => 'foobar'
    );
    my $rdb = {};
    my $edb = {
        entities => [ { type => 'boombaz', value => 'foobar' } ],
    };
    ok ($extractor->user_defined_entity_element($good_test_element, $rdb), "user def entity found");
    ok (!$extractor->user_defined_entity_element($bad_test_element, $rdb), "non user def entity found");
    cmp_deeply($rdb, $edb, "Entity DB is correct");
}

sub test_is_not_leaf_node {
    my $leaf = "foobar";
    my $nonleaf = HTML::Element->new('span');

    ok (! $extractor->is_not_leaf_node($leaf), "leaf detected");
    ok ($extractor->is_not_leaf_node($nonleaf), "Non leaf detected");
}

sub test_add_entity {
    my $edb = {};
    my $expected = {
        entities => [
            { type => 'foo', value => 'bar' }
        ]
    };

    $extractor->add_entity($edb, "foo", "bar");

    cmp_deeply($edb, $expected, "add_entity works");
}

sub test_ipaddr_action {
    my $edb = {};
    my $ipobs   = '10{.}10{.}10{.}1';
    my $ip      = '192.168.1.1';

    my $span    = $extractor->ipaddr_action($ipobs, $edb);
    my $expected_span = qq|<span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span>|;
    my $expected_edb = {
        entities => [
            { type => 'ipaddr', value => '10.10.10.1' },
            { type => 'ipaddr', value => '192.168.1.1' }
        ],
    };

    is ($span->as_HTML, $expected_span, "span is correct for $ipobs");
    
    $span = $extractor->ipaddr_action($ip, $edb);
    $expected_span = qq|<span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.1.1">192.168.1.1</span>|;

    is ($span->as_HTML, $expected_span, "span is correct for $ip");
    cmp_deeply($edb, $expected_edb, "Entity DB is correct");
}

sub test_fix_weird_html {
    my $splunk_ip4_node    = HTML::Element->new_from_lol(
        [ 'div', ['em', '10'], '.',
                 ['em', '10'], '.',
                 ['em', '10'], '.',
                 ['em', '1' ],
        ]
    );

    $extractor->fix_weird_html($splunk_ip4_node);
    my $html = $splunk_ip4_node->as_HTML;

    my $expect = '10.10.10.1';

    is ($html, $expect, "Fixed Splunk IPv4 weirdness");

    my $splunk_ip6_node = HTML::Element->new_from_lol(
        ['div', ['span', 2600, { class => "t a" } ],
                ':',
                ['span', 387, { class => "t a" } ],
                ':',
                ['span', 8, { class => "t a" } ],
                ':',
                ['span', 'f', { class => "t a" } ],
                ':0:0:0:',
                ['span', 'a5', { class => "t a" } ],
        ]
    );
    $extractor->fix_weird_html($splunk_ip6_node);
    $html   = $splunk_ip6_node->as_HTML;
    $expect = '2600:287:8:f:0:0:0:a5';
    is ($html, $expect, "Fixed Splunk IPv6 weirdness");

}

sub test_email_action {
    my $email = 'tbruner@sandia.gov';
    my $expect_span = q|<span class="entity email" data-entity-type="email" data-entity-value="tbruner@sandia.gov">tbruner@<span class="entity domain" data-entity-type="domain" data-entity-value="sandia.gov">sandia.gov</span></span>|;
    my $expect_edb  = {
        entities => [
            { type => 'domain', value => 'sandia.gov' },
            { type => 'email',  value => 'tbruner@sandia.gov' },
        ],
    };
    my $got_db  = {};
    my $got_span_element = $extractor->email_action($email, $got_db);
    my $got_span = $got_span_element->as_HTML;

    is ($got_span, $expect_span, "Email action span is correct");
    cmp_deeply($got_db, $expect_edb, "Entity DB correct");
}

