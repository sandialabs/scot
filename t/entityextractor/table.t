#!/usr/bin/env perl
use lib '../../lib';

use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Util::EntityExtractor;
use Scot::Env;

my $extractor   = Scot::Util::EntityExtractor->new();
my $source      = <<'EOF';
<table>
    <tr>
        <th>Ipaddr</th><th>email address</th>
    </tr>
    <tr>
        <td><div>10.10.1.2</div> foo</td><td>todd@sandia.gov</td>
    </tr>
</table>
EOF

my $flair   = <<'EOF';
<div><table><tr><th>Ipaddr </th><th>email address </th></tr><tr><td><div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.1.2">10.10.1.2</span> </div> foo </td><td><span class="entity email" data-entity-type="email" data-entity-value="todd@sandia.gov">todd@sandia.gov</span> </td></tr></table></div>
EOF

chomp($flair);

my $plain = <<'EOF';
   Ipaddr

   email address

   10.10.1.2 foo

   todd@sandia.gov
EOF

chomp($plain);

my $result  = $extractor->process_html($source);

my @entities = (
    {
        'type' => 'ipaddr',
        'value' => '10.10.1.2'
    },
    {
        'value' => 'todd@sandia.gov',
        'type' => 'email'
    },
);

my @sorted = sort { $a->{value} cmp $b->{value} } @{$result->{entities}};
print Dumper(@sorted);
print Dumper(@entities);

ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
cmp_bag(\@entities, \@sorted, "Entities are correct");

is($result->{flair}, $flair, "Flair is correct");

my @plain_words = split(/\s+/, $plain);
my @post_words  = split(/\s+/, $result->{text});

is (scalar(@plain_words), scalar(@post_words), "text has same number of words");

foreach my $pw (@post_words) {
    my $expected = shift @plain_words;
    is ($pw, $expected, "$pw matches");
}


# print Dumper($result);
done_testing();
exit 0;
