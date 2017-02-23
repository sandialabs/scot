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
my $source      = <<'EOF';
<html>Lets make sure that the router at <em>192</em>.<em>168</em>.<em>0</em>.<em>1</em> is still working</html>
EOF

my $flair   = <<'EOF';
<div>Lets make sure that the router at <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span> is still working </div>
EOF

chomp($flair);

my $plain = <<'EOF';
Lets make sure that the router at 192.168.0.1 is still working
EOF

chomp($plain);

my $result  = $extractor->process_html($source);
print Dumper($result);

my @entities = (
    { 'value' => '192.168.0.1', 'type' => 'ipaddr' }
);

ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
cmp_bag(\@entities, $result->{entities}, "entities correct");
is($result->{flair}, $flair, "Flair correct");

done_testing();
exit 0;

