#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(signatures say);
no warnings qw(experimental::signatures);
use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Log::Log4perl;
# use Scot::Env;

Log::Log4perl::init('../../../../etc/log.conf');



require_ok("Scot::Flair3::Worker");
my $worker  = Scot::Flair3::Worker->new(
    workers => 1,
    queue   => '/queue/flairtest',
    topic   => '/topic/flairtest',
);

my $stomp   = $worker->stomp;
ok (defined $stomp, "stomp defined in worker");
is (ref($stomp), 'Scot::Flair3::Stomp', "stomp is correct type");

my $package = "Scot::Flair3::Engine";
require_ok($package);

say Dumper($stomp);

my $engine      = Scot::Flair3::Engine->new({stomp => $stomp});
ok(defined $engine, "engine initialized");

# must create an $env obj otherwise get default singleton
# because Scot::Collection uses $env.  need to fix that
# my $env = Scot::Env->new({ config_file => './test.cfg.pl'});

my $extractor   = $engine->extractor;
ok (defined $extractor, "Extractor initialized");
is (ref($extractor), "Scot::Flair3::Extractor", "and the right type");

my $io   = $engine->io;
ok (defined $io, "Io initialized");
is (ref($io), "Scot::Flair3::Io", "and the right type");

my $imgmunger   = $engine->imgmunger;
ok (defined $imgmunger, "imgmunger initialized");
is (ref($imgmunger), "Scot::Flair3::Imgmunger", "and the right type");

my $regex    = $engine->regex;
ok (defined $regex, "Core Regex initialized");
is (ref($regex), "Scot::Flair3::Regex", "and the right type");

my $reload_message = { data    => { options => { reload => 1 } } };

is ($engine->process_topic($reload_message), 'success', "Message is a reload request");

my $non_html    = "Foo strikes again!";
my $got         = $engine->clean_html($non_html);

is ($got, '<div>Foo strikes again!</div>', "Cleaned plain texted");

my $non_html_utf8 = "ᚻᛖ ᚳᚹᚫᚦ ᚦᚫᛏ ᚻᛖ ᛒᚢᛞᛖ ᚩᚾ ᚦᚫᛗ ᛚᚪᚾᛞᛖ ᚾᚩᚱᚦᚹᛖᚪᚱᛞᚢᛗ ᚹᛁᚦ ᚦᚪ ᚹᛖᛥᚫ";
$got              = $engine->clean_html($non_html_utf8);

is ($got, '<div>ᚻᛖ ᚳᚹᚫᚦ ᚦᚫᛏ ᚻᛖ ᛒᚢᛞᛖ ᚩᚾ ᚦᚫᛗ ᛚᚪᚾᛞᛖ ᚾᚩᚱᚦᚹᛖᚪᚱᛞᚢᛗ ᚹᛁᚦ ᚦᚪ ᚹᛖᛥᚫ</div>', "Cleaned utf8 text");

my $sentinel_uri = 'https://sentinel.azure.com';
$got    = $engine->flair_special_sentinel($sentinel_uri);

is($got, '<a href="https://sentinel.azure.com" target="_blank"><img alt="view in Azure Sentinel" src="/images/azure-sentinel.png" /></a>', "Special flair Sentinal ok");

my @spark   = (
    '##__SPARKLINE__##',
    '0',
    '1',
    '2',
    '3',
);

my @norm = $engine->normalize_sparkline_data(\@spark);
is (scalar(@norm), 5, "normalized sparkline has correct number of elements");
is ($norm[1], 0, "Element 1 is correct");
is ($norm[3], 2, "Element 3 is correct");

my $sparkstring = "##__SPARKLINE__##,0,1,2,3";
@norm = $engine->normalize_sparkline_data([$sparkstring]);
is (scalar(@norm), 5, "normalized sparkstring in array has correct number of elements");
is ($norm[1], 0, "Element 1 is correct");
is ($norm[3], 2, "Element 3 is correct");

@norm = $engine->normalize_sparkline_data($sparkstring);
is (scalar(@norm), 5, "normalized sparkstring has correct number of elements");
is ($norm[1], 0, "Element 1 is correct");
is ($norm[3], 2, "Element 3 is correct");

my $svg = $engine->process_sparkline(\@spark);
my $exp = '<svg height="12" viewBox="0 -11 7 12" width="7" xmlns="http://www.w3.org/2000/svg"><polyline fill="none" points="0,0 2,-3.33 4,-6.67 6,-10" stroke="blue" stroke-linecap="round" stroke-width="1" /></svg>';
is($svg, $exp, "Got expected SVG");

my $aref    = [ 1, 2, 3 ];
my $nonaref = "1,2,3";

my @new = $engine->ensure_array($aref);
is (scalar(@new), 3, "Correctly sized array returned");
@new = $engine->ensure_array($nonaref);
is (scalar(@new), 1, "Correctly stuffed scalar into array");

my $htmltext    = '<html><body><p>Foobar</p><p>happens</p></body></hmtl>';
my $tree        = $engine->build_html_tree($htmltext);
is(ref($tree),"HTML::Element", "Built a tree from html");

my $singlediv   = '<html><body><div>foobar</div></body></html>';
$tree   = $engine->build_html_tree($singlediv);
my $html    = $engine->generate_flair_html($tree);
is($html, '<div>foobar</div>', "Generated single div flair html");

my $preflair = '<html><body><p><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span></p></body></html>';
$tree   = $engine->build_html_tree($preflair);
$html   = $engine->generate_flair_html($tree);
# print "$html\n";
is ($html, '<div><p><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span></div>', "Generated correct flair html");

my $entityspan = $extractor->create_span("foobar", "test");
is ($engine->is_special_class($entityspan), 1, "Is a special span ".$entityspan->as_HTML);


done_testing();
exit 0;
