#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(signatures say);
no warnings qw(experimental::signatures);
use lib '../../../../lib';
use DateTime;
use Test::More;
use Test::Deep;
use Data::Dumper;
use Log::Log4perl;
use Scot::Env;
use File::Slurp;
use Meerkat;

my $env = Scot::Env->new({config_file => './test.cfg.pl'});

my $log = Log::Log4perl->get_logger('flair_test');
my $pattern = "%d %7p [%P] %15F{1}: %4L %m%n";
my $layout  = Log::Log4perl::Layout::PatternLayout->new($pattern);
my $appender= Log::Log4perl::Appender->new(
    'Log::Log4perl::Appender::File',
    name        => 'flair_log',
    filename    => '/var/log/scot/test.log',
    autoflush   => 1,
    utf8        => 1,
);
$appender->layout($layout);
$log->add_appender($appender);
$log->level("TRACE");

my $mongo   = Meerkat->new(
    model_namespace         => 'Scot::Model',
    collection_namespace    => 'Scot::Collection',
    database_name           => 'scot-test',
    client_options          => {
        host        => 'mongodb://localhost',
        w           => 1,
        find_master => 1,
        socket_timeout_ms => 600000,
    }
);

ok(defined $mongo, "Meerkat was defined");
is(ref($mongo), "Meerkat", "correct type");

my $col = $mongo->collection('Entry');
is (ref($col), "Scot::Collection::Entry", "Got a collection");

my $queue   = "/queue/flairtest";
my $topic   = "/topic/scottest";

require_ok("Scot::Flair3::Io");
my $io  = Scot::Flair3::Io->new(
    log     => $log,
    mongo   => $mongo,
    queue   => $queue,
    topic   => $topic,
);

ok (defined $io, "IO was defined");
is (ref($io), "Scot::Flair3::Io", "The correct type");

require_ok("Scot::Flair3::Imgmunger");
my $imgmunger = Scot::Flair3::Imgmunger->new(io => $io);


my $simplehtml  = q{<html><body><img src="https://foo.com/foo.png" alt="zoofar"/></body></html>};
my $simpletree  = $imgmunger->build_tree($simplehtml);
my @images      = $simpletree->extract_links('img');
my ($oalt, $osrc);
foreach my $i (@{$simpletree->extract_links('img')}) {
    my ($u, $e, $a, $tag) = @$i;
    $oalt = $a;
    $osrc = $u;
    $imgmunger->rewrite_img_element($e, '/cached_images/foo.png', $u);
}
foreach my $i (@{$simpletree->extract_links('img')}) {
    my ($u, $e, $a, $tag) = @$i;
    is ($e->attr('src'), '/cached_images/foo.png', 'src updated');
    is ($e->attr('alt'), "Cached $osrc (zoofar)", "alt updated");
}


# done_testing();
# exit 0;


my $html    = do { local $/ = undef; <DATA> }; # "slurp" entire __DATA__ section into $html
my $tree    = $imgmunger->build_tree($html);
is(ref($tree), "HTML::Element", "build a tree");

my $new    = $imgmunger->process_body(123, $html);
chomp($new);

my $good = <<EOF;
<body><img alt="Cached https://www.sandia.gov/app/uploads/sites/72/2021/06/scot.png (no original alt)" src="/cached_images/2021/123/scot.png" /><h1>Some Title</h1><p>Some text<img alt="Cached Embedded  (dataUri)" src="/cached_images/2021/123/f86bd1b63ef82c679b3d388b9ee269af.png" /></body>
EOF
chomp($good);

is($new, $good, "HTML is good");

done_testing();
exit 0;
__DATA__
<html>
  <body>
    <img src="https://www.sandia.gov/app/uploads/sites/72/2021/06/scot.png">
    <h1>Some Title</h1>
    <p>Some text</p>
    <img src="data:image/png;base64,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">
  <body>
</html>
