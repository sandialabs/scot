#!/usr/bin/env perl
use lib '../../lib';

use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Util::EntityExtractor;
use Scot::Env;

my $extractor   = Scot::Util::EntityExtractor->new();
my $source      = <<'EOF';
<html>The attack <a href="www.attacker.com/asdf">www.attacker.com/asdf</a>  foo</html>
EOF

print "----------- SOURCE --------------\n";
print $source."\n";
print "---------------------------------\n";

my $flair   = <<'EOF';
<html><head></head><body><p>The attack <a href="www.attacker.com/asdf"><span class="entity domain" data-entity-type="domain" data-entity-value="www.attacker.com">www.attacker.com</span>/asdf </a>  foo </body></html>
EOF

chomp($flair);

my $plain = <<'EOF';
   The attack www.attacker.com/asdf foo
EOF

chomp($plain);

my $result  = $extractor->process_html($source);

my @entities = (
    {
        value   => 'www.attacker.com',
        type    => 'domain',
    }
);

ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
# cmp_bag(@entities, $result->{entities}, "Entities Correct");
is($result->{flair}, $flair, "Flair Correct");

my @plainwords  = split(/\s+/,$plain);
my @gotwords    = split(/\s+/,$result->{text});

foreach my $pw (@plainwords) {
    is ( shift @gotwords, $pw, "$pw Matches in plaintext");
}

# print Dumper($result);
done_testing();
exit 0;


