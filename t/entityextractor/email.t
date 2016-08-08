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

my $extractor   = Scot::Util::EntityExtractor->new({
    log => $log
});
my $source      = <<'EOF';
<div>tbruner@sandia.gov</div>
EOF

my $flair   = <<'EOF';
<div><div><span class="entity email" data-entity-type="email" data-entity-value="tbruner@sandia.gov">tbruner@<span class="entity domain" data-entity-type="domain" data-entity-value="sandia.gov">sandia.gov</span></span> </div></div>
EOF

chomp($flair);

my $plain = <<'EOF';
   tbruner@sandia.gov
EOF

chomp($plain);

my $result  = $extractor->process_html($source);

my @entities = (
    {
        'value' => 'sandia.gov',
        'type' => 'domain'
    },
    {
        'value' => 'tbruner@sandia.gov',
        'type' => 'email'
    },
);

my @sorted = sort { $a->{value} cmp $b->{value} } @{$result->{entities}};
print Dumper(@sorted);
print "-------\n";
print Dumper(@entities);

ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
cmp_bag(\@entities, \@sorted, "Entities are correct");

is($result->{flair}, $flair, "Flair is correct");

# my @plain_words = split(/\s+/, $plain);
# my @post_words  = split(/\s+/, $result->{text});

# is (scalar(@plain_words), scalar(@post_words), "text has same number of words");

# foreach my $pw (@post_words) {
#     my $expected = shift @plain_words;
#     is ($pw, $expected, "$pw matches");
# }


# print Dumper($result);
done_testing();
exit 0;
