#!/usr/bin/env perl
use lib '../lib';

use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;

my $env = Scot::Env->new({
    config_file     => '../scot.conf',
});
my $extractor   = $env->entity_extractor;

$source = q|http://pki1devsys.scot.org:8000/en-US/app/TEP_Analytics/pdm_monitoring?form.user=calojek&earliest=1404194400&latest=1406786400|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'text' => 'http://pki1devsys.scot.org:8000/en-US/app/TEP_Analytics/pdm_monitoring?form.user=calojek&earliest=1404194400&latest=1406786400',
          'flair' => '<html><head></head><body><p>http://<span class="entity domain" data-entity-type="domain" data-entity-value="pki1devsys.scot.org">pki1devsys.<span class="entity domain" data-entity-type="domain" data-entity-value="scot.org">scot.org</span></span>:8000/en-US/app/TEP_Analytics/pdm_monitoring?form.user=calojek&amp;earliest=1404194400&amp;latest=1406786400</body></html>',
          'entities' => [
                          {
                            'value' => 'pki1devsys.scot.org',
                            'type' => 'domain'
                          },
                          {
                            'value' => 'scot.org',
                            'type' => 'domain'
                          }
                        ]
 };
cmp_deeply ( $entity_href, $expected_href, "Properly matched a URL when it is first match" );

my $source   = <<EOF;
<html>  Attack originated from <a href="www.attacker.com/asdf">www.attacker.com/asdf</a> </html>
EOF
my $html;
my $plain;
my $entity_href = $extractor->process_html($source);
my $expected_href   = {
    'flair' => q|<html><head></head><body><p> Attack originated from <a href="www.attacker.com/asdf"><span class="entity domain" data-entity-type="domain" data-entity-value="www.attacker.com">www.<span class="entity domain" data-entity-type="domain" data-entity-value="attacker.com">attacker.com</span></span>/asdf</a></body></html>|,
    'text'  => q| Attack originated from www.attacker.com/asdf|,
    'entities'  => [
        { value => 'www.attacker.com', type => 'domain' },
        { value => 'attacker.com',  type => 'domain'}
    ],
};

cmp_deeply( $entity_href, $expected_href, "Does not alter the attributes of a <a href>");

# print Dumper($entity_href);

$source = q|<html>192.168.0.1 is the IP address of your router! Exclaimed the investigative computer scientist</html>|;
$entity_href = $extractor->process_html($source);
$expected_href = {
    'flair' => q|<html><head></head><body><p><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span> is the IP address of your router! Exclaimed the investigative computer scientist</body></html>|, 
    'text' => q|192.168.0.1 is the IP address of your router! Exclaimed the investigative computer scientist|,
    'entities'  =>[ { 'value' => '192.168.0.1', 'type' => 'ipaddr' } ],
};
cmp_deeply( $entity_href, $expected_href, "Entity at beginning of Element parses correctly");

# print Dumper($entity_href);

$source = q|<html>Make sure to check to see if we have blocked google.com</html>|;
$entity_href = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><p>Make sure to check to see if we have blocked <span class="entity domain" data-entity-type="domain" data-entity-value="google.com">google.com</span></body></html>',
    'text' => 'Make sure to check to see if we have blocked google.com',
    'entities' => [
        {
        'value' => 'google.com',
        'type' => 'domain'
        },
        ]
        };
cmp_deeply( $entity_href, $expected_href, "Entity at End correctly extracted");

$source = q|<html>Lets make sure that the router at <em>192</em>.<em>168</em>.<em>0</em>.<em>1</em> is still working</html>|;
$entity_href = $extractor->process_html($source);
$expected_href = {
    'flair' => '<html><head></head><body><p>Lets make sure that the router at <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span> is still working</body></html>',
   'text' => 'Lets make sure that the router at 192.168.0.1 is still working',
   'entities' => [
        { 'value' => '192.168.0.1', 'type' => 'ipaddr' }
   ]
};
cmp_deeply ( $entity_href, $expected_href, "Parsing of SPLUNK em enriched IP addrs works");

$source = q|<html><table><tr><th>Main IP</th><th>Count</th></tr><tr><td>192.168.0.1</td><td>55</td></tr><tr><td>192.168.0.5</td><td>4</td></tr></table></html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><table><tr><th>Main IP</th><th>Count</th></tr><tr><td><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span></td><td>55</td></tr><tr><td><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.5">192.168.0.5</span></td><td>4</td></tr></table></body></html>',
    'text' => 'Main IPCount192.168.0.155192.168.0.54',
    'entities' => [
        { 'value' => '192.168.0.1', 'type' => 'ipaddr' },
        { 'value' => '192.168.0.5', 'type' => 'ipaddr' }
    ]
};
cmp_deeply ( $entity_href, $expected_href, "Can handle tables reasonably");

$source = q|<html>Issues identified => 2.<br>192.168.0.1 => Attacker IP</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><p>Issues identified =&gt; 2.<br /><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span> =&gt; Attacker IP</body></html>',
    'text' => 'Issues identified => 2.192.168.0.1 => Attacker IP',
    'entities' => [
        {
        'value' => '192.168.0.1',
        'type' => 'ipaddr'
        }
    ]
};
cmp_deeply ( $entity_href, $expected_href, "Can handle <br> reasonably");

$source = q|<html><div Can you see 192.168.0.1 from there?</div>or 134.253.14.200</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><div 192.168.0.1="192.168.0.1" can="Can" from="from" see="see" there?</div="there?&lt;/div" you="you">or <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="134.253.14.200">134.253.14.200</span></div></body></html>',
    'text' => 'or 134.253.14.200',
    'entities' => [
        { 'value' => '134.253.14.200', 'type' => 'ipaddr' }
    ]
};
cmp_deeply ( $entity_href, $expected_href, "Can handle broken html reasonably");

$source = q|<html><script>alert(9)</script>192.168.0.1</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head><script>alert(9)</script></head><body><p><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span></body></html>',
    'text' => '192.168.0.1',
    'entities' => [
        { 'value' => '192.168.0.1', 'type' => 'ipaddr' }
    ]
};
cmp_deeply ( $entity_href, $expected_href, "Can handle javascript tags reasonably");

$source = q|<html><img src="http://www.scot.org/_assets/images/features/fiber-optic-network.jpg"></img>192.168.0.1</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><p><img src="http://www.scot.org/_assets/images/features/fiber-optic-network.jpg" /><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span></body></html>',
    'text' => '192.168.0.1',
    'entities' => [
        { 'value' => '192.168.0.1', 'type' => 'ipaddr' }
    ]
};
cmp_deeply ( $entity_href, $expected_href, "Can handle img tags reasonably, but doesnt render safe");

$source = q|<html>Feel free to reply to my message, my email is foobarius@gmail.com so let me know</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><p>Feel free to reply to my message, my email is <span class="entity email" data-entity-type="email" data-entity-value="foobarius@gmail.com"><span class="entity emailuser" data-entity-type="emailuser" data-entity-value="foobarius">foobarius</span>@<span class="entity domain" data-entity-type="domain" data-entity-value="gmail.com">gmail.com</span></span> so let me know</body></html>',
    'text' => 'Feel free to reply to my message, my email is foobarius@gmail.com so let me know',
    'entities' => [
        { 'value' => 'foobarius@gmail.com', 'type' => 'email' },
        { 'value' => 'gmail.com', 'type' => 'domain' }, 
        { 'value' => 'foobarius', 'type' => 'emailuser' },
    ] 
};
cmp_deeply ( $entity_href, $expected_href, "Can handle entities as part of other entities");

$source = q|<html> Free cruise to the Caribbean just email nick"p@gmail.com</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><p> Free cruise to the Caribbean just email nick&quot;<span class="entity email" data-entity-type="email" data-entity-value="p@gmail.com"><span class="entity emailuser" data-entity-type="emailuser" data-entity-value="p">p</span>@<span class="entity domain" data-entity-type="domain" data-entity-value="gmail.com">gmail.com</span></span></body></html>',
    'text' => ' Free cruise to the Caribbean just email nick"p@gmail.com',
    'entities' => [
        { 'value' => 'p@gmail.com', 'type' => 'email' },
        { 'value' => 'gmail.com', 'type' => 'domain' },
        { 'value' => 'p', 'type' => 'emailuser' },
    ]
};
cmp_deeply ( $entity_href, $expected_href, "Can handle a double quote reasonably");

# this test is broken. need to handle this special case
$source = q|<html>The email is 52523125458596548565232548565845@foo.com</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><p>The email is <span class="entity email" data-entity-type="email" data-entity-value="52523125458596548565232548565845@foo.com"><span class="entity emailuser" data-entity-type="emailuser" data-entity-value="52523125458596548565232548565845">52523125458596548565232548565845</span>@<span class="entity domain" data-entity-type="domain" data-entity-value="foo.com">foo.com</span></span></body></html>',
    'entities' => [
        {
            'value' => '52523125458596548565232548565845@foo.com',
            'type' => 'email'
        },
        {
            'type' => 'domain',
            'value' => 'foo.com'
        },
        {
            'type' => 'emailuser',
            'value' => '52523125458596548565232548565845'
        }
    ],
    'text' => 'The email is 52523125458596548565232548565845@foo.com'
};
cmp_deeply ( $entity_href, $expected_href, "Can handle md5 as a username in an email");


$source = q|<html>I didn't break md5 52523125458596548565232548565845 , did I?</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'text' => 'I didn\'t break md5 52523125458596548565232548565845 , did I?',
    'entities' => [
        { 'value' => '52523125458596548565232548565845', 'type' => 'md5' }
    ],
    'flair' => '<html><head></head><body><p>I didn&#39;t break md5 <span class="entity md5" data-entity-type="md5" data-entity-value="52523125458596548565232548565845">52523125458596548565232548565845</span> , did I?</body></html>'
};
cmp_deeply ( $entity_href, $expected_href, "Can find a naked md5");

$source = q|<html>code like this: out.append(chr(x)) could fool this.</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><p>code like this: out.append(chr(x)) could fool this.</body></html>',
    'text' => 'code like this: out.append(chr(x)) could fool this.',
    'entities' => [],
};
cmp_deeply ( $entity_href, $expected_href, "doesn't mistake obj oriented code for a domain as long as a parenthese is attached");

$source = q|<html>code like this: out.append could fool this.</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><p>code like this: out.append could fool this.</body></html>',
    'text' => 'code like this: out.append could fool this.',
    'entities' => [],
};
cmp_deeply ( $entity_href, $expected_href, "does mistake obj oriented code for a domain, which is OK"); 


$source = q|<html>find 3 domains: foo.com g.com really.long.org</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><p>find 3 domains: <span class="entity domain" data-entity-type="domain" data-entity-value="foo.com">foo.com</span> <span class="entity domain" data-entity-type="domain" data-entity-value="g.com">g.com</span> <span class="entity domain" data-entity-type="domain" data-entity-value="really.long.org">really.<span class="entity domain" data-entity-type="domain" data-entity-value="long.org">long.org</span></span></body></html>',
    'text' => 'find 3 domains: foo.com g.com really.long.org',
    'entities' => [
        {value=>"foo.com", type=>"domain"},
        {value=>"g.com", type=>"domain"},
        {value=>"really.long.org", type=>"domain"},
        {value=>"long.org", type=>"domain"},
    ],
};
cmp_deeply ( $entity_href, $expected_href, "find 3 domains");

$source = q|<html>an IP and a version: 10.1.1.1 1.2.3.4.5</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><p>an IP and a version: <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.1.1.1">10.1.1.1</span> 1.2.3.4.5</body></html>',
    'text' => 'an IP and a version: 10.1.1.1 1.2.3.4.5',
    'entities' => [
        {value=>"10.1.1.1", type=>"ipaddr"},
    ],
};
cmp_deeply ( $entity_href, $expected_href, "find ip not mib");

$source = q|<html>malware.exe is not a domain!</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><p><span class="entity file" data-entity-type="file" data-entity-value="malware.exe">malware.exe</span> is not a domain!</body></html>',
    'text' => 'malware.exe is not a domain!',
    'entities' => [
        { 'value' => 'malware.exe', 'type' => 'file' },
    ]    
};
cmp_deeply ( $entity_href, $expected_href, "malware.exe did not match as a domain name");

$source = q|this file foo.bar is cool.  foo.exe is not|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><p>this file foo.bar is cool. <span class="entity file" data-entity-type="file" data-entity-value="foo.exe">foo.exe</span> is not</body></html>',
    'text' => 'this file foo.bar is cool. foo.exe is not',
    'entities' => [
        { 'value' => 'foo.exe', 'type' => 'file' },
    ]    
};
cmp_deeply ( $entity_href, $expected_href, "foo.exe did match as a domain name");

done_testing();
exit 0;

 # debug
 # print Dumper($t->tx->res->json), "\n";
 # done_testing();
 # exit 0;
