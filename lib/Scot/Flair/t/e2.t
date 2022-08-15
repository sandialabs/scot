#!/usr/bin/env perl

use strict;
use warnings;
use lib '../../../../lib';
use lib '.';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use Scot::Model::Entry;
use E2TestSamples;
use HTML::Element;
use feature qw(say);

my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new({config_file => $config_file});
my $timer       = $env->get_timer("All Test Completed");

ok (defined $env, "Environment defined");
ok (ref($env) eq "Scot::Env", "It is a Scot::Env");

require_ok('Scot::Flair::Engine');
my $engine = Scot::Flair::Engine->new(env => $env);

ok(defined $engine, "extractor module instantiated");

my $e2samples = E2TestSamples->new();

test_samples();
test_regex_build();
test_external_defined_entity_class();
test_add_entity();
test_ipaddr_action();
test_email_action();
&$timer;
done_testing();

sub test_regex_build {
    my $r = $engine->regexes->all;
    #foreach my $re (@$r) {
    #    print Dumper($re);
    #}
    print scalar(@$r)." regexes available\n";
}

sub test_samples {
    my @samples    = ();
    push @samples, 
#         $e2samples->build_deep_recursion_problem,
#        $e2samples->build_flair_error_tests,
#        $e2samples->build_local_tests,
#        $e2samples->build_domain_tests,
#        $e2samples->build_ipv4_tests,
#        $e2samples->build_ipv6_tests,
#        $e2samples->build_email_tests,
#        $e2samples->build_cve_tests,
#        $e2samples->build_cidr_tests,
        $e2samples->build_message_id_tests;
#        $e2samples->build_id_tests,
#        $e2samples->build_file_tests;
    

    foreach my $sample (@samples) {
        my $testname = $sample->{name};
        my $source   = $sample->{source};
        my $flair    = $sample->{flair};
        my $edb      = $sample->{entities};
        $env->log->debug("------- Test $testname ------------");
        my ($gotedb, $gotflair, $gottext) = $engine->extract_from_html($source);


        ok(compare_edb($gotedb->{entities}, $edb), "$testname EDB is correct") || die;

        my $expect_flair_text = $engine->extractor->build_html(@$flair);

        is($gotflair, $expect_flair_text, "$testname HTML Flair matches") or flair_text_mismatch($gotflair, $expect_flair_text);
    }
}

sub flair_text_mismatch {
    my $g = shift;
    my $e = shift;

    if (! defined $g) {
        done_testing();
        die "Got null back from engine!";
    }

    for (my $i = 0; $i < length($g); $i++) {
        my $x = substr($g, $i, 1);
        my $y = substr($e, $i, 1);

        if ( $x ne $y ) {
            print "[$x|$y]\n";
            done_testing();
            exit 1;
        }
        print $x;
    }
}

sub compare_edb {
    my $got = shift;
    my $exp = shift;

    foreach my $gt (keys %$got) {
        foreach my $gk (keys %{$got->{$gt}}) {
            my $gr = $got->{$gt}->{$gk};
            my $er = $exp->{$gt}->{$gk};
            if ( $gr != $er ) {
                print "Type $gt Value $gk did not match! g = $gr e = $er\n";
                print "Got ".Dumper($got)."\n";
                print "Exp ".Dumper($exp)."\n";
                return undef;
            }
        }
    }
    return 1;
}



sub dump_entities {
    my $got = shift;
    my $exp = shift;
    print Dumper($got,$exp);
    done_testing();
    exit;
}

sub compare_new_array {
    my $got_aref    = shift;
    my $exp_aref    = shift;

    if (scalar(@$got_aref) != scalar(@$exp_aref)) {
        print_array_comparrison($got_aref, $exp_aref);
    }

    for (my $i = 0; $i < scalar(@$got_aref); $i++ ) {
        my $gv = $got_aref->[$i];
        my $ev = $exp_aref->[$i];

        if ( ! ref($gv) ) {
            if ( $gv ne $ev ) {
                print "Element mismatch!\n";
                print "Index $i\n";
                print "Got   : $gv\n";
                print "Expect: $ev\n";
                done_testing();
                exit 1;
            }
        }
        else {
            compare_element($gv, $ev);
        }
    }
    return 1;
}

sub compare_element {
    my $g   = shift;
    my $e   = shift;

    if ($g->tag ne $e->tag) {
        print "Tag Names Differ!\n";
        print "    got: ".$g->tag."\n";
        print " expect: ".$e->tag."\n";
        done_testing();
        exit;
    }
    my @attrs = ('class', 'data-entity-type', 'data-entity-value');

    foreach my $attr (@attrs) {
        if ($g->attr($attr) ne $e->attr($attr)) {
            print "Element $attr differs! \n";
            print "    got: ".Dumper($g->attr($attr))."\n";
            print " expect: ".Dumper($e->attr($attr))."\n";
            done_testing();
            exit;
        }
    }

}

sub highlight_string_diff {
    my $g   = shift;
    my $e   = shift;

    for (my $i = 0; $i < length($g); $i++) {
        my $gc = substr $g, $i, 1;
        my $ec = substr $e, $i, 1;

        if ( $gc ne $ec ) {
            print ">$gc<";
        }
        else {
            print "$gc";
        }
    }
}

sub print_array_comparrison {
    my $g   = shift;
    my $e   = shift;

    my $gmax    = scalar(@$g);
    my $emax    = scalar(@$e);

    my $max = ($gmax > $emax) ? $gmax : $emax;

    for (my $i = 0; $i < $max; $i++) {
        my $gv  = $g->[$i] // '';
        my $ev  = $e->[$i] // '';
        $gv = $gv->as_HTML if ref($gv);
        $ev = $ev->as_HTML if ref($ev);
        printf "%3d  ------------------------------------------\n",$i;
        print "g: ".$gv."\n";
        print "e: ".$ev."\n";
        # print "g: ".Dumper($gv)."\n";
        # print "e: ".Dumper($ev)."\n";
        print  "-----------------------------------------------\n";
    }
    done_testing();
    exit 1;
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
        entities => { 'boombaz' => {'foobar'=> 1 } },
    };
    ok ($engine->extractor->user_defined_entity_element($good_test_element, $rdb), "user def entity found");
    ok (!$engine->extractor->user_defined_entity_element($bad_test_element, $rdb), "non user def entity found");
    cmp_deeply($rdb, $edb, "Entity DB is correct") or print Dumper($rdb,$edb);
}

sub test_add_entity {
    my $edb = {};
    my $expected = {
        entities => {
             'foo' => {'bar'=>1}
        },
    };

    $engine->extractor->add_entity($edb, "bar", "foo");

    cmp_deeply($edb, $expected, "add_entity works");
}

sub test_ipaddr_action {
    my $edb = {};
    my $ipobs   = '10{.}10{.}10{.}1';
    my $ip      = '192.168.1.1';

    my $span    = $engine->extractor->ipaddr_action($ipobs, $edb);
    my $expected_span = qq|<span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span>|;
    my $expected_edb = {
        entities => {
            'ipaddr' => { '10.10.10.1' => 1,
                          '192.168.1.1' => 1
            },
        },
    };

    is ($span->as_HTML, $expected_span, "span is correct for $ipobs");
    
    $span = $engine->extractor->ipaddr_action($ip, $edb);
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

    $engine->extractor->fix_weird_html($splunk_ip4_node);
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
    $engine->extractor->fix_weird_html($splunk_ip6_node);
    $html   = $splunk_ip6_node->as_HTML;
    $expect = '2600:287:8:f:0:0:0:a5';
    is ($html, $expect, "Fixed Splunk IPv6 weirdness");

}

sub test_email_action {
    my $email = 'tbruner@sandia.gov';
    my $expect_span = q|<span class="entity email" data-entity-type="email" data-entity-value="tbruner@sandia.gov">tbruner@<span class="entity domain" data-entity-type="domain" data-entity-value="sandia.gov">sandia.gov</span></span>|;
    my $expect_edb  = {
        entities => {
            'domain'=> {'sandia.gov' => 1 },
            'email' => {'tbruner@sandia.gov' => 1 },
        },
    };
    my $got_db  = {};
    my $got_span_element = $engine->extractor->email_action($email, $got_db);
    my $got_span = $got_span_element->as_HTML;

    is ($got_span, $expect_span, "Email action span is correct");
    cmp_deeply($got_db, $expect_edb, "Entity DB correct");
}

