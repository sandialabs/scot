#!/usr/bin/env perl
use lib '../../lib';

use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Util::EntityExtractor;
use Scot::Util::Config;
use Scot::Util::LoggerFactory;
my $logfactory = Scot::Util::LoggerFactory->new({
    config_file => 'logger_test.cfg',
    paths       => [ '../../../Scot-Internal-Modules/etc' ],
});
my $log = $logfactory->get_logger;
my $extractor   = Scot::Util::EntityExtractor->new({log=>$log});
my $source      = <<EOF;
...truncated...
EOF

my $flair   = <<EOF;
<div>...truncated...</div>
EOF

chomp($flair);

my $plain = <<EOF;
...truncated...
EOF

chomp($plain);

my $result  = $extractor->process_html($source);
print Dumper($result);

my @entities = (
);

ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
cmp_bag(\@entities,$result->{entities}, "Entities correct");
is($flair, $result->{flair}, "Flair correct");

done_testing();
exit 0;
