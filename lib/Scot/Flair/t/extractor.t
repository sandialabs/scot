#!/usr/bin/env perl

use strict;
use warnings;
use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use Scot::Flair::Engine;

my $env         = Scot::Env->new({config_file => "./test.cfg.pl"});
my $engine      = Scot::Flair::Engine->new(env => $env);
my $extractor   = $engine->extractor;

is ($extractor->external_defined_entity_class(), 0, "external_defined_entity returns false for undef class");
is ($extractor->external_defined_entity_class('userdef'), 1, "external_defined_entity returns true for userdef");
is ($extractor->external_defined_entity_class('ghostbuster'), 1,"external_defined_entity returns true for ghostbuster");
is ($extractor->external_defined_entity_class('foobar'), 0, "external_defined_entity returns true for foobar");

my $ude_good1 = HTML::Element->new('span', 'class' => 'userdef', 'data-entity-type' => 'ipaddr', 'data-entity-value' => '10.10.10.1');
my $ude_good2 = HTML::Element->new('span', 'class' => 'ghostbuster', 'data-entity-type' => 'ipaddr', 'data-entity-value' => '10.10.10.1');
my $ude_bad1  = HTML::Element->new('span', 'class' => 'ghostbuster');
my $ude_bad2  = HTML::Element->new('div', 'class' => 'text');

is ($extractor->user_defined_entity_element($ude_good1, {}), 1, "user_defined_entity_element detected a user defined element (userdef)");
is ($extractor->user_defined_entity_element($ude_good2, {}), 1, "user_defined_entity_element detected a user defined element (ghostbuster)");
is ($extractor->user_defined_entity_element($ude_bad1, {}), undef, "user_defined_entity_element detected a misidentified user defined element (ghostbuster no data-entity-*)");
is ($extractor->user_defined_entity_element($ude_bad2, {}), undef, "user_defined_entity_element rejected a not span");

my $good_domain = "scot.sandia.gov";
my $bad_domain  = "foobar.heeebygeeby";
is ($extractor->get_root_domain($good_domain), "sandia.gov", "get_root_domain: Got Root Domain for valid domain");
is ($extractor->get_root_domain($bad_domain), undef, "get_root_domain: Returned false for non-existent domain");

# domain action
my $bad_domain2 = "boombaz.heeebygeeby";
my $edb     = {
    cache   => {
        domain_fp   => {
            $bad_domain2 => 1
        }
    }
};

my $span1 = $extractor->create_span($good_domain, "domain");

is ($extractor->domain_action($good_domain, $edb, 0)->as_HTML, $span1->as_HTML, "domain_action: created valid span for good domain");
is ($extractor->domain_action($bad_domain, $edb, 0), undef, "domain_action: returned false for bad domain");
is ($extractor->domain_action($bad_domain2, $edb, 0), undef, "domain_action: returned false for bad domain in false positive cache");


my $ipv6    = "2603:10b6:5:13:0:0:0:22";
my $span_ipv6 = $extractor->create_span($ipv6, "ipv6");
my $notip6  = "aa:aa:aa:aa:aa:12";


is ($extractor->ipv6_action($ipv6)->as_HTML, $span_ipv6->as_HTML, "ipv6_action: correctly handled an ipv6 address");
is ($extractor->ipv6_action($notip6), undef, "ipv6_action: correctly handled an invalid ipv6 address");

# ipaddr_action
my $ipaddrs = {
    '10.10.10.1'        => $extractor->create_span('10.10.10.1', 'ipaddr'),
    '10{.}10{.}10{.}1'  => $extractor->create_span('10.10.10.1', 'ipaddr'),
    '10[.]10[.]10[.]1'  => $extractor->create_span('10.10.10.1', 'ipaddr'),
    '10(.)10(.)10(.)1'  => $extractor->create_span('10.10.10.1', 'ipaddr'),
    '10.10.10(.)1'      => $extractor->create_span('10.10.10.1', 'ipaddr'),
    '10.10.10{.}1'      => $extractor->create_span('10.10.10.1', 'ipaddr'),
    '10.10.10[.]1'      => $extractor->create_span('10.10.10.1', 'ipaddr'),
};

foreach my $ipa (keys %$ipaddrs) {
    my $ipdb    = {};
    is ($extractor->ipaddr_action($ipa, $ipdb)->as_HTML, $ipaddrs->{$ipa}->as_HTML, "ipaddr_action: correct span for $ipa");
    is ($ipdb->{entities}->{ipaddr}->{$extractor->deobsfucate_ipdomain($ipa)}, 1, "ipaddr_action: EDB correctly set") || print Dumper($ipdb);
}

# email_action
my $espan1  = HTML::Element->new_from_lol([
    'span', 
    { 
        class => 'entity email', 
        'data-entity-type' => "email", 
        'data-entity-value'=>'tbruner@sandia.gov'
    },
    'tbruner',
    '@',
    [   'span', 
        {
            class   => 'entity domain',
            'data-entity-type'  => 'domain',
            'data-entity-value' => 'sandia.gov',
        },
        'sandia.gov',
    ]
]);
my $emails  = {
    'tbruner@sandia.gov'    => {
        span    => $espan1,
        domain  => 'sandia.gov',
    },
};

foreach my $em (keys %$emails) {
    my $emdb    = {};
    is ($extractor->email_action($em, $emdb)->as_HTML, $emails->{$em}->{span}->as_HTML, "email_action: correct span for $em");
    is ($emdb->{entities}->{email}->{$em}, 1, "email_action: EDB email correctly set");
    is ($emdb->{entities}->{domain}->{$emails->{$em}->{domain}}, 1, "email_action EDB domain correctly set");
}

# message_id_action 

my $msgid1  = '<adfadfadsfads@sadfa.gov>';
my $msgdb   = {};
is ($extractor->message_id_action($msgid1, $msgdb)->as_HTML, $extractor->create_span($msgid1, "message_id")->as_HTML, "message_id_action: correctly created span for $msgid1");
is ($msgdb->{entities}->{message_id}->{$msgid1}, 1, "message_id_action: EDB correctly set") || print Dumper($msgdb);

# cidr_action
my $cidr1   = '10.10.10.1/24';
my $cidrdb  = {};
is ($extractor->cidr_action($cidr1, $cidrdb)->as_HTML, $extractor->create_span($cidr1, "cidr")->as_HTML, "cidr_action: correctly created span for cidr block $cidr1");
is ($cidrdb->{entities}->{cidr}->{$cidr1}, 1, "cidr_action: EDB correctly set");

# deobsfucate, tested in other stuff, but explicitly here
my $deobs   = {
    'foo[.]bar[.]com'   => 'foo.bar.com',
    'sandia(.)gov'      => 'sandia.gov',
    '10.10.10(.)1'      => '10.10.10.1',
    '10.10.10[.]1'      => '10.10.10.1',
    '10.10.10{.}1'      => '10.10.10.1',
    '10.10.10.1'        => '10.10.10.1',
};

foreach my $deob (keys %$deobs) {
    is ($extractor->deobsfucate_ipdomain($deob), $deobs->{$deob}, "deobsfucate_ipdomain: correctly deobsfucated $deob");
}

# add_entity
my $test_edb    = {};
$extractor->add_entity($test_edb, "foo.com", "domain");
$extractor->add_entity($test_edb, "foo.com", "domain");
$extractor->add_entity($test_edb, "10.10.10.1", "ipaddr");
is ($test_edb->{entities}->{domain}->{'foo.com'}, 2, "add_entity: correctly summed foo.com");
is ($test_edb->{entities}->{ipaddr}->{'10.10.10.1'}, 1, "add_entity: correctly added 10.10.10.1");

# create_span
is ($extractor->create_span("foo","bar")->as_HTML, '<span class="entity bar" data-entity-type="bar" data-entity-value="foo">foo</span>', "create_span: works");
