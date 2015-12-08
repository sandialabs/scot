#!/usr/bin/env perl
use lib '../../lib';

use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use Scot::Util::EntityExtractor;

my $extractor   = Scot::Util::EntityExtractor->new();
my $source      = <<'EOF';
List of weird ipaddres:
<table>
    <tr>
        <th>Host</th><th>IPaddr</th>
    </tr>
    <tr>
        <td>foobar</td><td>10{.}10{.}10{.}1</td>
    </tr>
    <tr>
        <td>boombaz</td><td>20[.]20[.]20[.]20</td>
    </tr>
</table>    
EOF

my $flair   = <<'EOF';
<html><head></head><body><p>List of weird ipaddres:<br /><table><tr><th>Host </th><th>IPaddr </th></tr><tr><td>foobar </td><td><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span> </td></tr><tr><td>boombaz </td><td><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="20.20.20.20">20.20.20.20</span> </td></tr></table></body></html>
EOF

chomp($flair);

my $plain = <<'EOF';
   List of weird ipaddres:

   Host

   IPaddr

   foobar

   10.10.10.1

   boombaz

   20.20.20.20
EOF

chomp($plain);

my $result  = $extractor->process_html($source);
print Dumper($result);

my @entities = (
        {
        'value' => '10.10.10.1',
        'type' => 'ipaddr'
        },
        {
        'type' => 'ipaddr',
        'value' => '20.20.20.20'
        }
);

ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
cmp_bag(\@entities, $result->{entities}, "entities correct");
is($result->{flair}, $flair, "Flair correct");

done_testing();
exit 0;

