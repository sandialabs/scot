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
This has some zeros:
0

0 0

0 0 0 

:0

0.0.0.0
</html>
EOF

my $flair   = <<'EOF';
<div><br />This has some zeros:<br />0<br />0 0<br />0 0 0<br />:0<br /><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="0.0.0.0">0.0.0.0</span><br /></div>
EOF

chomp($flair);

my $plain = <<'EOF';
This has some zeros:
0
0 0
0.0.0.0
EOF

chomp($plain);

my $result  = $extractor->process_html($source);
print Dumper($result);

my @entities = (
    {
    'value' => '0.0.0.0',
    'type' => 'ipaddr'
    }
);

ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
cmp_bag(\@entities, $result->{entities}, "entities correct");
is($result->{flair}, $flair, "Flair correct");

done_testing();
exit 0;

