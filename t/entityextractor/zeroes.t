#!/usr/bin/env perl
use lib '../../lib';

use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Util::EntityExtractor;
use Scot::Util::Config;
use Scot::Util::Logger;
my $confobj = Scot::Util::Config->new({
    paths   => ['../../../Scot-Internal-Modules/etc/'],
    file    => 'logger_test.cfg',
});
my $loghref = $confobj->get_config();
print Dumper($loghref);
my $log     = Scot::Util::Logger->new($loghref);

$log->debug("STARTING EE TEST");

my $extractor   = Scot::Util::EntityExtractor->new({log=>$log});
my $source      = <<'EOF';
<html>
This has some zeros:
0

0 0

0.0.0.0
</html>
EOF

my $flair   = <<'EOF';
<div>
</div>
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
    'value' => '192.168.0.1',
    'type' => 'ipaddr'
    }
);

ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
cmp_bag(\@entities, $result->{entities}, "entities correct");
is($result->{flair}, $flair, "Flair correct");

done_testing();
exit 0;

