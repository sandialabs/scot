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
my $log     = Scot::Util::Logger->new($loghref);
my $extractor   = Scot::Util::EntityExtractor->new({log=>$log});
my $source      = <<'EOF';
<html><script>alert(9)</script>192.168.0.1</html>
EOF

my $flair   = <<'EOF';
<div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span> </div>
EOF

chomp($flair);

my $plain = <<'EOF';
   192.168.0.1
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

