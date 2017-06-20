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
my $extractor   = Scot::Util::EntityExtractor->new({
    log => $log
});
my $source      = <<'EOF';
<div>scot-dev@watermelon.gov
   mailman-bounces@trixios.org</div>
EOF

my $flair   = <<'EOF';
<div><div><span class="entity email" data-entity-type="email" data-entity-value="scot-dev@watermelon.gov">scot-dev@<span class="entity domain" data-entity-type="domain" data-entity-value="watermelon.gov">watermelon.gov</span></span><br /><span class="entity email" data-entity-type="email" data-entity-value="mailman-bounces@trixios.org">mailman-bounces@<span class="entity domain" data-entity-type="domain" data-entity-value="trixios.org">trixios.org</span></span> </div></div>
EOF

chomp($flair);

my $plain = <<'EOF';
   scot-dev@watermelon.gov
EOF

chomp($plain);

my $result  = $extractor->process_html($source);

my @entities = (
    {
        'value' => 'watermelon.gov',
        'type' => 'domain'
    },
    {
        'value' => 'trixios.org',
        'type' => 'domain'
    },
    {
        'value' => 'scot-dev@watermelon.gov',
        'type' => 'email'
    },
    {
        'value' => 'mailman-bounces@trixios.org',
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
