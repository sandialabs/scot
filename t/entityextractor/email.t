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
    This is a list of emails:
    todd@www.todd.com
    boo@foo.bar.org
    yuk@172.16.4.4
    user@34net.net
Useless text here.

    BOO@zoo.com
    Boo@Zoo.com
    boo@ZOO.com
    boo@zoo.com
EOF

my $flair   = <<'EOF';
<div>    This is a list of emails:<br /><span class="email" data-entity-type="email" data-entity-value="todd@www.todd.com">todd@<span class="entity domain" data-entity-type="domain" data-entity-value="www.todd.com">www.todd.com</span></span><br /><span class="email" data-entity-type="email" data-entity-value="boo@foo.bar.org">boo@<span class="entity domain" data-entity-type="domain" data-entity-value="foo.bar.org">foo.bar.org</span></span><br />yuk@<span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="172.16.4.4">172.16.4.4</span><br /><span class="email" data-entity-type="email" data-entity-value="user@34net.net">user@<span class="entity domain" data-entity-type="domain" data-entity-value="34net.net">34net.net</span></span><br />Useless text here.<br /><span class="email" data-entity-type="email" data-entity-value="BOO@zoo.com">BOO@<span class="entity domain" data-entity-type="domain" data-entity-value="zoo.com">zoo.com</span></span><br /><span class="email" data-entity-type="email" data-entity-value="Boo@zoo.com">Boo@<span class="entity domain" data-entity-type="domain" data-entity-value="zoo.com">zoo.com</span></span><br /><span class="email" data-entity-type="email" data-entity-value="boo@zoo.com">boo@<span class="entity domain" data-entity-type="domain" data-entity-value="zoo.com">zoo.com</span></span><br /><span class="email" data-entity-type="email" data-entity-value="boo@zoo.com">boo@<span class="entity domain" data-entity-type="domain" data-entity-value="zoo.com">zoo.com</span></span><br /></div>
EOF
chomp($flair);

my $plain = <<'EOF';
   This is a list of emails: todd@www.todd.com boo@foo.bar.org yuk@172.16.4.4
   user@34net.net
Uselesstexthere.
EOF

chomp($plain);

my $result  = $extractor->process_html($source);

# print Dumper($result);

my @entities = (
        {
        'type' => 'domain',
        'value' => 'www.todd.com'
        },
        {
        'type' => 'email',
        'value' => 'todd@www.todd.com'
        },
        {
        'type' => 'domain',
        'value' => 'foo.bar.org'
        },
        {
        'value' => 'boo@foo.bar.org',
        'type' => 'email'
        },
        {
        'type' => 'ipaddr',
        'value' => '172.16.4.4'
        },
        {
        'type' => 'domain',
        'value' => '34net.net'
        },
        {
        'value' => 'user@34net.net',
        'type' => 'email'
        },
        {
        'type' => 'domain',
        'value' => 'zoo.com'
        },
        {
        'value' => 'BOO@zoo.com',
        'type' => 'email'
        },
        {
        'value' => 'zoo.com',
        'type' => 'domain'
        },
        {
        'value' => 'Boo@Zoo.com',
        'type' => 'email'
        },
        {
        'type' => 'domain',
        'value' => 'zoo.com'
        },
        {
        'type' => 'email',
        'value' => 'boo@ZOO.com'
        },
        {
        'value' => 'zoo.com',
        'type' => 'domain'
        },
        {
        'value' => 'boo@zoo.com',
        'type' => 'email'
        }
);

ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
is($result->{flair}, $flair, "flair correct");
cmp_deeply($result->{entities}, \@entities,"entities correct");


# print Dumper($result);
done_testing();
exit 0;
