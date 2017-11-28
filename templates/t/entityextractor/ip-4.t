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
<html>
    <ul>list of ip obfuscations:
        <li>10[.]10[.]10[.]10</li>
        <li>10{.}10{.}10{.}10</li>
        <li>10(.)10(.)10(.)10</li>
</html>
EOF

my $flair   = <<'EOF';
<div><ul>list of ip obfuscations:<br /><li><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.10">10.10.10.10</span> <li><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.10">10.10.10.10</span> <li><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.10">10.10.10.10</span> </ul></div>
EOF

chomp($flair);

my $plain = <<'EOF';
list of ip obfuscations:
     * 10.10.10.10

     * 10.10.10.10

     * 10.10.10.10',
EOF

chomp($plain);

my $result  = $extractor->process_html($source);
print Dumper($result);

my @entities = (
    {
    'value' => '10.10.10.10',
    'type' => 'ipaddr'
    },
    {
    'value' => '10.10.10.10',
    'type' => 'ipaddr'
    },
    {
    'value' => '10.10.10.10',
    'type' => 'ipaddr'
    },
);

ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
cmp_bag(\@entities, $result->{entities}, "entities correct");
is($result->{flair}, $flair, "Flair correct");

done_testing();
exit 0;

