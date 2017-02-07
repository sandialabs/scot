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


my $extractor   = Scot::Util::EntityExtractor->new({log=>$log});
my $source      = <<'EOF';
<html>
PUT /api/people/1 HTTP/1.1
User-Agent: Mozilla/5.0 (Windows NT; Windows NT 6.2; en-US) WindowsPowerShell/4.0
Host: example.com
Content-Length: 0
Via: 1.1 sppy6005.watermelon.com (squid/3.1.23
X-Forwarded-For: 134.253.10.234
Cache-Control: max-age=259200
Connection: Keep-Alive

HTTP/1.1 405 Method Not Allowed
Cache-Control: max-age=604800
Date: Wed, 28 Sep 2016 16:53:26 GMT
Expires: Wed, 05 Oct 2016 16:53:26 GMT
Server: EOS (lax004/28A3)
Content-Length: 0
</html>
EOF

my $flair   = <<'EOF';
<div><br />PUT /api/people/1 HTTP/1.1<br />User-Agent: Mozilla/5.0 (Windows NT; Windows NT 6.2; en-US) WindowsPowerShell/4.0<br />Host: <span class="entity domain" data-entity-type="domain" data-entity-value="example.com">example.com</span><br />Content-Length: 0<br />Via: 1.1 <span class="entity domain" data-entity-type="domain" data-entity-value="sppy6005.watermelon.com">sppy6005.watermelon.com</span> (squid/3.1.23)<br />X-Forwarded-For: <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="134.253.10.234">134.253.10.234</span><br />Cache-Control: max-age=259200<br />Connection: Keep-Alive<br />HTTP/1.1 405 Method Not Allowed<br />Cache-Control: max-age=604800<br />Date: Wed, 28 Sep 2016 16:53:26 GMT<br />Expires: Wed, 05 Oct 2016 16:53:26 GMT<br />Server: EOS (lax004/28A3)<br />Content-Length: 0<br /></div>
EOF

chomp($flair);

my $plain = <<'EOF';
PUT /api/people/1 HTTP/1.1
User-Agent: Mozilla/5.0 (Windows NT; Windows NT 6.2; en-US)
WindowsPowerShell/4.0
Host: example.com
Content-Length: 0
Via: 1.1 sppy6005.watermelon.com (squid/3.1.23)
X-Forwarded-For: 134.253.10.234
Cache-Control: max-age=259200
Connection: Keep-Alive
HTTP/1.1 405 Method Not Allowed
Cache-Control: max-age=604800
Date: Wed, 28 Sep 2016 16:53:26 GMT
Expires: Wed, 05 Oct 2016 16:53:26 GMT
Server: EOS (lax004/28A3)
Content-Length: 0
EOF

chomp($plain);

my $result  = $extractor->process_html($source);
print Dumper($result);

my @entities = (
    {
    'type' => 'domain',
    'value' => 'example.com'
    },
    {
    'value' => 'sppy6005.watermelon.com',
    'type' => 'domain'
    },
    {
    'type' => 'ipaddr',
    'value' => '134.253.10.234'
    }
);

ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
cmp_bag(\@entities, $result->{entities}, "entities correct");
is($result->{flair}, $flair, "Flair correct");

done_testing();
exit 0;

