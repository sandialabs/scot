#!/usr/bin/env perl
use lib '../../lib';

use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Util::EntityExtractor;
use Scot::Env;

my $extractor   = Scot::Util::EntityExtractor->new();
my $source      = <<'EOF';
<html><script>alert(9)</script>192.168.0.1</html>
EOF

my $flair   = <<'EOF';
<html><head><script>alert(9) </script></head><body><p><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span> </body></html>
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

