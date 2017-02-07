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
# Added the following to the blocklist:<br><br><pre>foundersomaha.net <br>externalbatterycase.com <br>spoilrotn.com <br>veloelectric.com.au<br></pre>

#### I think this is just hoplessly broken due to the f'ed up nature of the HTML.

my $extractor   = Scot::Util::EntityExtractor->new({log=>$log});
my $source      = <<EOF;
Added the following to the blocklist:<br><br><pre>foo foundersomaha.net  meaningless <br>externalbatterycase.com some other post text</pre>
<p>nothing here</p>
<div>
    IP addr time:
    <em>10</em>.<em>10</em>.<em>10</em>.<em>10</em>
    123.123.123.123
</div>
EOF

my $flair   = <<EOF;
<div>Added the following to the blocklist: <br /><br /><pre>foo <span class="entity domain" data-entity-type="domain" data-entity-value="foundersomaha.net">foundersomaha.net</span>  meaningless <br /><span class="entity domain" data-entity-type="domain" data-entity-value="externalbatterycase.com">externalbatterycase.com</span> some other post text </pre><p>nothing here <div><br />IP addr time:<br /><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.10">10.10.10.10</span><br /><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="123.123.123.123">123.123.123.123</span><br /></div></div>
EOF

chomp($flair);

my $plain = <<EOF;
   Added the following to the blocklist:

   foo       foundersomaha.net        meaningless
   externalbatterycase.com       some       other       post       text

   nothing here


   IP addr time:
   10.10.10.10
   123.123.123.123
EOF

chomp($plain);

my $result  = $extractor->process_html($source);

my @entities = (
    {
    'value' => 'foundersomaha.net',
    'type' => 'domain'
    },
    {
    'value' => 'externalbatterycase.com',
    'type' => 'domain'
    },
    {
    'type' => 'ipaddr',
    'value' => '10.10.10.10'
    },
    {
    'type' => 'ipaddr',
    'value' => '123.123.123.123'
    }
);

ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
cmp_bag(\@entities,$result->{entities}, "Entities correct");
is($flair, $result->{flair}, "Flair correct");

# print Dumper($result);
done_testing();
exit 0;
