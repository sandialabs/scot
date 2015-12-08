#!/usr/bin/env perl
use lib '../../lib';

use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Util::EntityExtractor;
use Scot::Env;

my $extractor   = Scot::Util::EntityExtractor->new();
my $source      = <<'EOF';
    This is a list of emails:
    todd@www.todd.com
    boo@foo.bar.org
    yuk@172.16.4.4
    user@34net.net
Useless text here.
EOF

my $flair   = <<'EOF';
<html><head></head><body><p>    This is a list of emails:<br /><span class="entity email" data-entity-type="email" data-entity-value="todd@www.todd.com">todd@www.todd.com</span><br /><span class="entity email" data-entity-type="email" data-entity-value="boo@foo.bar.org">boo@foo.bar.org</span><br />yuk@<span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="172.16.4.4">172.16.4.4</span><br /><span class="entity email" data-entity-type="email" data-entity-value="user@34net.net">user@34net.net</span><br />Useless text here.<br /></body></html>
EOF

chomp($flair);

my $plain = <<'EOF';
   This is a list of emails: todd@www.todd.com boo@foo.bar.org yuk@172.16.4.4
   user@34net.netUselesstexthere.
EOF

chomp($plain);

my $result  = $extractor->process_html($source);

my @entities = (
    {
    'type' => 'email',
    'value' => 'todd@www.todd.com'
    },
    {
    'value' => 'boo@foo.bar.org',
    'type' => 'email'
    },
    {
    'value' => '172.16.4.4',
    'type' => 'ipaddr'
    },
    {
    'type' => 'email',
    'value' => 'user@34net.net'
    }
);

ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
is($result->{flair}, $flair, "flair correct");
cmp_deeply(\@entities, $result->{entities}, "entities correct");


# print Dumper($result);
done_testing();
exit 0;
