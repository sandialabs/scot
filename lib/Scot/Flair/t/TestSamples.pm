package TestSamples;

our @domain_samples = (
    {
        name    => 'scot-7397',
        source  => <<EOF,
https://cbase.som.sunysb.edu/soap/bss.cfm
EOF
        plain   => <<EOF,
https://cbase.som.sunysb.edu/soap/bss.cfm
EOF
        flair   => <<EOF, 
<div>https://<span class="entity domain" data-entity-type="domain" data-entity-value="cbase.som.sunysb.edu">cbase.som.sunysb.edu</span>/soap/<span class="entity file" data-entity-type="file" data-entity-value="bss.cfm">bss.cfm</span>
</div>
EOF
        entities => [
            { type => 'domain', value => 'cbase.som.sunysb.edu' },
            { type => 'file',   value => 'bss.cfm' },
        ],
    },
    {
        name    => 'google plain',
        source  => <<EOF,
www.google.com
EOF
        plain   => <<EOF,
www.google.com
EOF
        flair   => <<EOF, 
<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span></div>
EOF
        entities => [
            { type => 'domain', value => 'www.google.com' },
        ],
    },
    {
        name    => 'google obsfucated 1',
        source  => <<EOF,
www(.)google(.)com
EOF
        plain   => <<EOF,
www.google.com
EOF
        flair   => <<EOF, 
<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span></div>
EOF
        entities => [
            { type => 'domain', value => 'www.google.com' },
        ],
    },
    {
        name    => 'google obsfucated 2',
        source  => <<EOF,
www[.]google[.]com
EOF
        plain   => <<EOF,
www.google.com
EOF
        flair   => <<EOF, 
<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span></div>
EOF
        entities => [
            { type => 'domain', value => 'www.google.com' },
        ],
    },
    {
        name    => 'google obsfucated 3',
        source  => <<EOF,
www{.}google{.}com
EOF
        plain   => <<EOF,
www.google.com
EOF
        flair   => <<EOF, 
<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span></div>
EOF
        entities => [
            { type => 'domain', value => 'www.google.com' },
        ],
    },
    {
        name    => 'google obsfucated 4',
        source  => <<EOF,
www(.)google{.}com
EOF
        plain   => <<EOF,
www.google.com
EOF
        flair   => <<EOF, 
<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span></div>
EOF
        entities => [
            { type => 'domain', value => 'www.google.com' },
        ],
    },
    {
        name    => 'dotted hex string should not match domain',
        source  => <<EOF,
8a.93.8c.99.8d.61.62.86.97.88.86.91.91.8e.4e.97.8a.99
EOF
        plain   => <<EOF,
8a.93.8c.99.8d.61.62.86.97.88.86.91.91.8e.4e.97.8a.99
EOF
        flair   => <<EOF,
<div>8a.93.8c.99.8d.61.62.86.97.88.86.91.91.8e.4e.97.8a.99</div>
EOF
        entities    => [],
    },
    {
        name    => "domain with numeric component",
        source  => 'foo.10.com',
        plain   => 'foo.10.com',
        flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="foo.10.com">foo.10.com</span></div>',
        entities => [
            { value => 'foo.10.com', type => 'domain' },
        ],
    },
    {
        name    => "id domain",
        source  => <<'EOF',
<html>paziapm.co.id</html>
EOF
        plain   => <<'EOF',
paziapm.co.id
EOF
        flair   => <<'EOF',
<div><span class="entity domain" data-entity-type="domain" data-entity-value="paziapm.co.id">paziapm.co.id</span></div>
EOF
        entities    => [
            { value   => 'paziapm.co.id', type    => 'domain', },
        ],
    },
    {
        name    => "puny code 1",
        source      => <<'EOF',
foo.xn--p1ai
EOF
        plain       => <<'EOF',
foo.xn--p1ai
EOF
        flair       => <<'EOF',
<div><span class="entity domain" data-entity-type="domain" data-entity-value="foo.xn--p1ai">foo.xn--p1ai</span>
</div>
EOF
        entities    => [
            { value   => 'foo.xn--p1ai', type    => 'domain', },
        ],
        userdef => [],
    },
    {
        name    => "puny code 2",
        source      => <<'EOF',
xn--clapcibic1.xn--p1ai
EOF
        plain       => <<'EOF',
xn--clapcibic1.xn--p1ai
EOF
        flair       => <<'EOF',
<div><span class="entity domain" data-entity-type="domain" data-entity-value="xn--clapcibic1.xn--p1ai">xn--clapcibic1.xn--p1ai</span>
</div>
EOF
        entities    => [
            { value   => 'xn--clapcibic1.xn--p1ai', type    => 'domain', },
        ],
        userdef => [],
    },
    {
        name     => 'http[s] urls',
        source  => <<EOF,
<html>
    <div>
        <br>
        <div>https://groups.google.com/d/optout</div>
        <br>
        <div>http://todd.com/journal/123</div>
    </div>
</html>
EOF
        plain   => <<EOF,
   https://groups.google.com/d/optout
   http://todd.com/journal/123
EOF
        flair   => <<EOF,
<div><div><br /><div>https://<span class="entity domain" data-entity-type="domain" data-entity-value="groups.google.com">groups.google.com</span>/d/optout</div><br /><div>http://<span class="entity domain" data-entity-type="domain" data-entity-value="todd.com">todd.com</span>/journal/123</div></div></div>
EOF
        entities    => [
            {
                type    => "domain",
                value   => "groups.google.com",
            },
            {
                type    => "domain",
                value   => "todd.com",
            },
        ],
    },

);

our @html_examples = (
    {
        name    => "entities in html table",
        source  => <<'EOF',
<table>
<tr>
    <th>Ipaddr</th><th>email address</th>
</tr>
<tr>
    <td><div>10.10.1.2</div> foo</td><td>todd@watermelon.gov</td>
</tr>
</table>
EOF
        plain => << 'EOF',
   Ipaddr

   email address

   10.10.1.2 foo

   todd@watermelon.gov
EOF
        flair   => << 'EOF',
<div><table><tr><th>Ipaddr</th><th>email address</th></tr><tr><td><div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.1.2">10.10.1.2</span></div> foo</td><td><span class="entity email" data-entity-type="email" data-entity-value="todd@watermelon.gov">todd@<span class="entity domain" data-entity-type="domain" data-entity-value="watermelon.gov">watermelon.gov</span></span></td></tr></table></div>
EOF
        
        entities    => [
            {  value  => '10.10.1.2',           type => 'ipaddr'  },
            {  value  => 'todd@watermelon.gov', type => 'email' },
            {  value  => 'watermelon.gov',     type => 'domain' },
        ],

    },
    {
        name    => 'html with script',
        source  => <<'EOF',
<html><script>alert('boo');</script>192.168.1.1</html>
EOF
        plain   => <<EOF,
192.168.1.1
EOF
        flair   => <<EOF,
<div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.1.1">192.168.1.1</span></div>
EOF
        entities => [
            { value => '192.168.1.1', value => "ipaddr" },
        ],
    },
    {
        name    => "anchor discrimination",
        source  => <<EOF,
<html>The attack <a href="www.attacker.com/asdf">www.attacker.com/asdf</a>  foo</html>
EOF
        plain   => <<EOF,
The attack www.attacker.com/asdf foo
EOF
        flair   => <<EOF,
<div>The attack <a href="www.attacker.com/asdf"><span class="entity domain" data-entity-type="domain" data-entity-value="www.attacker.com">www.attacker.com</span>/asdf</a>  foo</div>
EOF
        entities    => [
            { value => 'www.attacker.com', type  => 'domain', },
        ],
    },
    {
        name    => "underscore in entity",
        source  => <<'EOF',
<html>It was todd_bruner@foo.com</html>
EOF
        plain   => <<'EOF',
It was todd_bruner@foo.com
EOF
        flair   => <<'EOF',
<div>It was <span class="entity email" data-entity-type="email" data-entity-value="todd_bruner@foo.com">todd_bruner@<span class="entity domain" data-entity-type="domain" data-entity-value="foo.com">foo.com</span></span></div>
EOF
        entities    => [
            { value   => 'todd_bruner@foo.com', type    => 'email', },
            { value   => 'foo.com', type    => 'domain', },
        ],
    },
    {
        name    => "Email with Capitalization",
        source  => <<'EOF',
<table>
<tr>
    <th>Ipaddr</th><th>email address</th>
</tr>
<tr>
    <td><div>10.10.1.2</div> foo</td><td>TODD@watermelon.gov</td>
</tr>
</table>
EOF
        plain => << 'EOF',
   Ipaddr

   email address

   10.10.1.2 foo

   TODD@watermelon.gov
EOF
        flair   => << 'EOF',
<div><table><tr><th>Ipaddr</th><th>email address</th></tr><tr><td><div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.1.2">10.10.1.2</span></div> foo</td><td><span class="entity email" data-entity-type="email" data-entity-value="todd@watermelon.gov">TODD@<span class="entity domain" data-entity-type="domain" data-entity-value="watermelon.gov">watermelon.gov</span></span></td></tr></table></div>
EOF
        
        entities    => [
            { 'type' => 'ipaddr', 'value' => '10.10.1.2' },
            { 'value' => 'todd@watermelon.gov', 'type' => 'email' },
            { value   => 'watermelon.gov', type    => 'domain', },
        ],

    },
    {
        name    => "Angle brackets suck part 2",
        source      => <<'EOF',
function Invoke-InternalMonologue
{
    <#
    .SYNOPSIS
    Retrieves NTLMv1 challenge-response for all available users
#>

$Source = @"
using System.Text.RegularExpressions;
    if ( foo > 0 ) {
        echo "this sux";
    }
EOF
        plain      => <<'EOF',
function Invoke-InternalMonologue { <# .SYNOPSIS Retrieves NTLMv1
   challenge-response for all available users #> $Source = @" using
   System.Text.RegularExpressions; if ( foo > 0 ) { echo "this sux"; }
EOF
    flair   => <<'EOF',
<div>function Invoke-InternalMonologue
{
    &lt;#
    .SYNOPSIS
    Retrieves NTLMv1 challenge-response for all available users
#&gt;

$Source = @&quot;
using System.Text.RegularExpressions;
    if ( foo &gt; 0 ) {
        echo &quot;this sux&quot;;
    }
</div>
EOF
        entities    => [
        ],
        userdef => [],
        debug   => 1,
    },
);

our @ipv4_examples = (
    {
        name    => "ipv4 in text with trailing comma",
        source  => <<EOF,
<html>It was a dark and stormy night when we received the ping from 192.168.1.4, and then the tests started failing.</html>
EOF
        plain   => <<EOF,
It was a dark and stormy night when we received the ping from 192.168.1.4,
   and then the tests started failing.
EOF
        flair   => <<EOF,
<div>It was a dark and stormy night when we received the ping from <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.1.4">192.168.1.4</span>, and then the tests started failing.</div>
EOF
        entities => [
            { value => '192.168.1.4', type => 'ipaddr' },
        ],
    },
    {
        name    => "ipv4 in text at end of sentence with period",
        source  => <<EOF,
<html>It was a dark and stormy night when we received the ping from 192.168.1.4. boom!</html>
EOF
        plain   => <<EOF,
It was a dark and stormy night when we received the ping from 192.168.1.4.
   boom!
EOF
        flair   => <<EOF,
<div>It was a dark and stormy night when we received the ping from <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.1.4">192.168.1.4</span>. boom!</div>
EOF
        entities => [
            { value => '192.168.1.4', type => 'ipaddr' },
        ],
    },
    {
        name    => "ipv4 in middle of text ",
        source  => <<EOF,
<html>It was a dark and stormy night when we received the ping from 192.168.1.4 boom baz!</html>
EOF
        plain   => <<EOF,
It was a dark and stormy night when we received the ping from 192.168.1.4
   boom baz!
EOF
        flair   => <<EOF,
<div>It was a dark and stormy night when we received the ping from <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.1.4">192.168.1.4</span> boom baz!</div>
EOF
        entities => [
            { value => '192.168.1.4', type => 'ipaddr' },
        ],
    },
    {
        name    => "ipv4 with various obsfuctions",
        source  => <<EOF,
<html>10(.)10(.)10(.)1<br>192[.]168[.]4[.]4<br>172{.}16{.}1{.}1<html>
EOF
        plain   => <<EOF,
10.10.10.1
   192.168.4.4
   172.16.1.1
EOF
        flair   => <<EOF,
<div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span><br /><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.4.4">192.168.4.4</span><br /><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="172.16.1.1">172.16.1.1</span></div>
EOF
        entities => [
            { value => '10.10.10.1', type => 'ipaddr' },
            { value => '192.168.4.4', type => 'ipaddr' },
            { value => '172.16.1.1', type => 'ipaddr' },
        ],
    },
    {
        name    => 'splunk style ipv4',
        source  => <<EOF,
<html>IP addr pasted from splunk is <em>10</em>.<em>10</em>.<em>10</em>.<em>1</em>.  Why?</html>
EOF
        plain   => <<EOF,
IP addr pasted from splunk is 10.10.10.1. Why?
EOF
        flair   => <<EOF,
<div>IP addr pasted from splunk is <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span>.  Why?</div>
EOF
        entities => [
            { value => '10.10.10.1', type => 'ipaddr' },
        ],
    },
    {
        name    => 'semi obsfucted ip addr',
        source  => <<EOF,
<html>
    <div>
        <p>10.126.188[.]212</p>
    </div>
</html>
EOF
        plain   => <<EOF,
   10.126.188.212
EOF
        flair   => <<EOF,
<div><div><p><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.126.188.212">10.126.188.212</span></div></div>
EOF
        entities    => [
            { type    => "ipaddr", value   => "10.126.188.212", },
        ],
    },
    {
        name    => 'leading ip4:',
        source  => <<EOF,
<html><p>
  ip4:65.38.177[.]13
</p></html>
EOF
        plain   => <<EOF,
   ip4:65.38.177.13
EOF
        flair   => <<EOF,
<div><p>
  ip4:<span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="65.38.177.13">65.38.177.13</span>
</div>
EOF
        entities    => [
            { 'type'    => 'ipaddr', 'value' => '65.38.177.13' }
        ],
    },
);

our @email_tests = (
    {
        name    => "email in text",
        source  => <<'EOF',
<html>Here's my email: tbruner@sandia.gov</html>
EOF
        plain   => <<'EOF',
Here's my email: tbruner@sandia.gov
EOF
        flair   => <<'EOF',
<div>Here&#39;s my email: <span class="entity email" data-entity-type="email" data-entity-value="tbruner@sandia.gov">tbruner@<span class="entity domain" data-entity-type="domain" data-entity-value="sandia.gov">sandia.gov</span></span></div>
EOF
        entities => [
            { value => 'sandia.gov', type => 'domain' },
            { value => 'tbruner@sandia.gov', type => 'email' },
        ],
    },
    {
        name    => "email",
        source  => << 'EOF',
user@thedomain[.]biz
EOF
        plain   => << 'EOF',
user@thedomain.biz
EOF
        flair   => << 'EOF',
<div><span class="entity email" data-entity-type="email" data-entity-value="user@thedomain.biz">user@<span class="entity domain" data-entity-type="domain" data-entity-value="thedomain.biz">thedomain.biz</span></span>
</div>
EOF
        entities    => [
            { 'value' => 'thedomain.biz', 'type' => 'domain' },
            { 'value' => 'user@thedomain.biz', 'type' => 'email' },
        ],
    },
    {
        name    => "email with =",
        source      => <<'EOF',
bounces+182497-1c5d-xxxx=watermelon.edu@email.followmyhealth.com
EOF
        plain       => <<'EOF',
bounces+182497-1c5d-xxxx=watermelon.edu@email.followmyhealth.com
EOF
        flair       => <<'EOF',
<div><span class="entity email" data-entity-type="email" data-entity-value="bounces+182497-1c5d-xxxx=watermelon.edu@email.followmyhealth.com">bounces+182497-1c5d-xxxx=watermelon.edu@<span class="entity domain" data-entity-type="domain" data-entity-value="email.followmyhealth.com">email.followmyhealth.com</span></span>
</div>
EOF
        entities    => [
            { value   => 'email.followmyhealth.com', type    => 'domain', },
            { value   => 'bounces+182497-1c5d-xxxx=watermelon.edu@email.followmyhealth.com', type    => 'email', },
        ],
        userdef => [],
        debug   => 1,
    },
);

our @cve_tests = (
    {
        name    => "flair cve refs",
        source  => <<'EOF',
<html>It was CVE-2017-12345</html>
EOF
        plain   => <<'EOF',
It was CVE-2017-12345
EOF
        flair   => <<'EOF',
<div>It was <span class="entity cve" data-entity-type="cve" data-entity-value="cve-2017-12345">CVE-2017-12345</span></div>
EOF
        entities    => [
            { value   => 'cve-2017-12345', type    => 'cve', },
        ],
    },
);

our @userdef_tests = (
    {
        name    => "user defined 1",
        source      => <<'EOF',
<html>This <span class="userdef" data-entity-type="actor" data-entity-value="fuzzy foobar">fuzzy foobar</span> is a real threat.</html>
EOF
        plain       => <<'EOF',
This fuzzy foobar is a real threat.
EOF
        flair       => <<'EOF',
<div>This <span class="entity actor" data-entity-type="actor" data-entity-value="fuzzy foobar">fuzzy foobar</span> is a real threat.</div>
EOF
        entities    => [
        ],
        userdef     => [
            { value   => 'fuzzy foobar', type    => 'actor', }
        ],
    },
    {
        name     => "user defined 2",
        source      => <<'EOF',
<html>This <span class="userdef" data-entity-type="actor" data-entity-value="fuzzy foobar">fuzzy foobar</span> is a real threat and operates from 10.10.10.1.</html>
EOF
        plain       => <<'EOF',
This fuzzy foobar is a real threat and operates from 10.10.10.1.
EOF
        flair       => <<'EOF',
<div>This <span class="entity actor" data-entity-type="actor" data-entity-value="fuzzy foobar">fuzzy foobar</span> is a real threat and operates from <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span>.</div>
EOF
        entities    => [
            { value   => '10.10.10.1', type    => 'ipaddr', }
        ],
        userdef     => [
            { value   => 'fuzzy foobar', type    => 'actor', }
        ],
    },
    {
        name    => "user defined 3",
        source      => <<'EOF',
<p>This is a test of <span class="userdef" data-entity-type="threat_group" data-entity-value="fuzzy foobar">fuzzy foobar</span></p>
EOF
        plain       => <<'EOF',
   This is a test of fuzzy foobar
EOF
        flair       => <<'EOF',
<div><p>This is a test of <span class="entity threat_group" data-entity-type="threat_group" data-entity-value="fuzzy foobar">fuzzy foobar</span></div>
EOF
        entities    => [
        ],
        userdef     => [
            { value   => 'fuzzy foobar', type    => 'threat_group', }
        ],
    },
    {
        name    => "JRock fun with user def",
        source      => <<'EOF',
<html>cmd.exe /c bcdedit /set {default} recoveryenabled No</html>
EOF
        plain       => <<'EOF',
cmd.exe /c bcdedit /set {default} recoveryenabled No
EOF
        flair       => <<'EOF',
<div><span class="entity file" data-entity-type="file" data-entity-value="cmd.exe">cmd.exe</span> /c <span class="entity jrock1" data-entity-type="jrock1" data-entity-value="bcdedit /set">bcdedit /set</span> {default} recoveryenabled No</div>
EOF
        entities    => [
            {
                value   => 'bcdedit /set',
                type    => 'jrock1',
            },
            {
                value   => "cmd.exe",
                type    => "file",
            },
        ],
        userdef => [
        ],
    },
    {
        name    => "SLIMHTTP/1.1",
        source      => <<'EOF',
SLIMHTTP/1.1
EOF
        plain       => <<'EOF',
SLIMHTTP/1.1
EOF
    flair           => <<'EOF',
<div><span class="entity user_agent" data-entity-type="user_agent" data-entity-value="slimhttp/1.1">SLIMHTTP/1.1</span></div>
EOF
    entities    => [
            { value   => 'slimhttp/1.1', type    => 'user_agent', }
    ],
    userdef => [],
    },
    {
        name    => "SRS Test One",
        source      => <<'EOF',
A129.5.5.5 A129.3.3.3 TESTING123
EOF
        plain       => <<'EOF',
A129.5.5.5 A129.3.3.3 TESTING123
EOF
        flair        => <<'EOF',
<div><span class="entity SRStestTwo" data-entity-type="SRStestTwo" data-entity-value="a129.5.5.5">A129.5.5.5</span> <span class="entity SRStestTwo" data-entity-type="SRStestTwo" data-entity-value="a129.3.3.3">A129.3.3.3</span> <span class="entity SRStestOne" data-entity-type="SRStestOne" data-entity-value="testing123">TESTING123</span>
</div>
EOF
    entities    => [
            { type    => "SRStestTwo", value   => "a129.5.5.5", },
            { type    => "SRStestTwo", value   => "a129.3.3.3", },
            { type    => "SRStestOne", value   => "testing123", }
    ],
    userdef => [],
    },
    {
        name    => "SRS Test Two",
        source      => <<'EOF',
<div>A129.5.5.5 &nbsp;A129.3.3.3&nbsp;TESTING123</div>
EOF
        plain       => "A129.5.5.5 ".chr(160)."A129.3.3.3".chr(160)."TESTING123",
        flair        => <<'EOF',
<div><div><span class="entity SRStestTwo" data-entity-type="SRStestTwo" data-entity-value="a129.5.5.5">A129.5.5.5</span> &nbsp;<span class="entity SRStestTwo" data-entity-type="SRStestTwo" data-entity-value="a129.3.3.3">A129.3.3.3</span>&nbsp;<span class="entity SRStestOne" data-entity-type="SRStestOne" data-entity-value="testing123">TESTING123</span></div></div>
EOF
    entities    => [
        { type    => "SRStestTwo", value   => "a129.5.5.5", },
        { type    => "SRStestTwo", value   => "a129.3.3.3", },
        { type    => "SRStestOne", value   => "testing123", }
    ],
    userdef => [],
    },

);

our @laika_tests = (
    {
        name    => "LaikaBoss signature flair 1",
        source      => <<'EOF',
<html>yr:misc_google_amp_link_s75_1</html>
EOF
        plain       => <<'EOF',
yr:misc_google_amp_link_s75_1
EOF
        flair       => <<'EOF',
<div><span class="entity lbsig" data-entity-type="lbsig" data-entity-value="yr:misc_google_amp_link_s75_1">yr:misc_google_amp_link_s75_1</span></div>
EOF
        entities    => [
            { value   => 'yr:misc_google_amp_link_s75_1', type    => 'lbsig', }
        ],
        userdef => [
        ],
    },
    {
        name    => "LaikaBoss signature flair 2",
        source      => <<'EOF',
<html>yr:misc_vbaproj_codepage_foreign_s63_1</html>
EOF
        plain       => <<'EOF',
yr:misc_vbaproj_codepage_foreign_s63_1
EOF
        flair       => <<'EOF',
<div><span class="entity lbsig" data-entity-type="lbsig" data-entity-value="yr:misc_vbaproj_codepage_foreign_s63_1">yr:misc_vbaproj_codepage_foreign_s63_1</span></div>
EOF
        entities    => [
            { value   => 'yr:misc_vbaproj_codepage_foreign_s63_1', type    => 'lbsig', }
        ],
        userdef => [
        ],
    },
);

our @cidr_tests = (
    {
        name        => "cidr1",
        source      => <<'EOF',
10.10.10.0/30
EOF
        plain       => <<'EOF',
10.10.10.0/30
EOF
        flair       => <<'EOF',
<div><span class="entity cidr" data-entity-type="cidr" data-entity-value="10.10.10.0/30">10.10.10.0/30</span>
</div>
EOF
        entities    => [
            { value   => '10.10.10.0/30', type    => 'cidr', }
        ],
        userdef => [
        ],
    },
    {
        name    => 'semi obsfucted cidr addr',
        source  => <<EOF,
<html>
    <div>
        <p>10.126.188[.]212/2</p>
    </div>
</html>
EOF
        plain   => <<EOF,
   10.126.188.212/2
EOF
        flair   => <<EOF,
<div><div><p><span class="entity cidr" data-entity-type="cidr" data-entity-value="10.126.188.212/2">10.126.188.212/2</span></div></div>
EOF
        entities    => [
            { type    => "cidr", value   => "10.126.188.212/2", },
        ],
    },
);

our @file_tests = (
    {
        name    => "file1",
        source      => <<'EOF',
invoice.pdf.exe
EOF
        plain       => <<'EOF',
invoice.pdf.exe
EOF
    flair           => <<'EOF',
<div><span class="entity file" data-entity-type="file" data-entity-value="invoice.pdf.exe">invoice.pdf.exe</span>
</div>
EOF
    entities    => [
            {
                value   => 'invoice.pdf.exe',
                type    => 'file',
            }
    ],
    userdef => [],
    },
    {
        name     => "file2",
        source      => <<'EOF',
haxor.py
EOF
        plain       => <<'EOF',
haxor.py
EOF
    flair           => <<'EOF',
<div><span class="entity file" data-entity-type="file" data-entity-value="haxor.py">haxor.py</span>
</div>
EOF
        entities    => [
                { value   => 'haxor.py', type    => 'file', }
        ],
        userdef => [],
    },
    {
        name    => "filename fail",
        source      => <<'EOF',
Sep 10, 2018 07:33:38 AM Error [ajp-nio-8016-exec-6] - Error Executing Database Query.[Macromedia][SQLServer JDBC Driver][SQLServer]Incorrect syntax near '='. The specific sequence of files included or processed is: /mnt/gfs/cfdocs/eCATT/templates/pgas_rslts.cfm, line: 235
EOF
        plain       => <<'EOF',
Sep 10, 2018 07:33:38 AM Error [ajp-nio-8016-exec-6] - Error Executing
   Database Query.[Macromedia][SQLServer JDBC Driver][SQLServer]Incorrect
   syntax near '='. The specific sequence of files included or processed
   is: /mnt/gfs/cfdocs/eCATT/templates/pgas_rslts.cfm, line: 235
EOF
        flair       => <<'EOF',
<div>Sep 10, 2018 07:33:38 AM Error [ajp-nio-8016-exec-6] - Error Executing Database Query.[Macromedia][SQLServer JDBC Driver][SQLServer]Incorrect syntax near &#39;=&#39;. The specific sequence of files included or processed is: /mnt/gfs/cfdocs/eCATT/templates/<span class="entity file" data-entity-type="file" data-entity-value="pgas_rslts.cfm">pgas_rslts.cfm</span>, line: 235
</div>
EOF
        entities    => [
            { value   => 'pgas_rslts.cfm', type    => 'file', },
        ],
        userdef => [],
    },

);

our @ipv6_tests = (
    {
        name    => 'ipv6-1',
        source      => <<'EOF',
1762:0:0:0:0:B03:1:AF18
EOF
        plain       => <<'EOF',
1762:0:0:0:0:B03:1:AF18
EOF
        flair       => <<'EOF',
<div><span class="entity ipv6" data-entity-type="ipv6" data-entity-value="1762:0:0:0:0:b03:1:af18">1762:0:0:0:0:B03:1:AF18</span>
</div>
EOF
        entities    => [
            { value   => '1762:0:0:0:0:b03:1:af18', type    => 'ipv6', }
        ],
        userdef => [],
    },
    {
        name     => 'ipv6-1a',
        source      => <<'EOF',
1762::b03:1:af18
EOF
        plain       => <<'EOF',
1762::b03:1:af18
EOF
        flair       => <<'EOF',
<div><span class="entity ipv6" data-entity-type="ipv6" data-entity-value="1762::b03:1:af18">1762::b03:1:af18</span>
</div>
EOF
        entities    => [
            { value   => '1762::b03:1:af18', type    => 'ipv6', }
        ],
        userdef => [],
    },
    {
        name     => 'ipv6-3',
        source      => <<'EOF',
2001:41d0:2:9d17::
EOF
        plain       => <<'EOF',
2001:41d0:2:9d17::
EOF
        flair       => <<'EOF',
<div><span class="entity ipv6" data-entity-type="ipv6" data-entity-value="2001:41d0:2:9d17::">2001:41d0:2:9d17::</span>
</div>
EOF
        entities    => [
            { value   => '2001:41d0:2:9d17::', type    => 'ipv6', }
        ],
        userdef => [],
    },
    {
        name     => "event 14246 ipv6 problem",
        source      => <<'EOF',
by BN6PR27MB2539.namprd13.prod.poutlook.org (2603:10b6:404:129::18)
EOF
        plain       => <<'EOF',
by BN6PR27MB2539.namprd13.prod.poutlook.org (2603:10b6:404:129::18)
EOF
        flair       => <<'EOF',
<div>by <span class="entity domain" data-entity-type="domain" data-entity-value="bn6pr27mb2539.namprd13.prod.poutlook.org">BN6PR27MB2539.namprd13.prod.poutlook.org</span> (<span class="entity ipv6" data-entity-type="ipv6" data-entity-value="2603:10b6:404:129::18">2603:10b6:404:129::18</span>)
</div>
EOF
        entities    => [
                { type    => "domain", value   => "bn6pr27mb2539.namprd13.prod.poutlook.org", },
                { type    => "ipv6", value   => "2603:10b6:404:129::18", },
        ],
        userdef => [],
    },
    {
        name    => "false ipv6",
        source      => <<'EOF',
toys::file
EOF
        plain       => <<'EOF',
toys::file
EOF
        flair       => <<'EOF',
<div>toys::file
</div>
EOF
        entities    => [
        ],
        userdef => [],
        debug   => 1,
    },
    {
        name    => 'suricata ipv6 with port',
        source      => <<EOF,
<html>
    <div>
        <p>2001:489a:2202:2000:0000:0000:0000:0009:53 -> 2620:0106:6008:009b:00f0:0000:0000:0021:57239</p>
    </div>
</html>
EOF
        plain       => <<EOF,
   2001:489a:2202:2000:0000:0000:0000:0009:53 ->
   2620:0106:6008:009b:00f0:0000:0000:0021:57239
EOF
        flair       => <<EOF,
<div><div><p><span class="entity ipv6" data-entity-type="ipv6" data-entity-value="2001:489a:2202:2000:0000:0000:0000:0009">2001:489a:2202:2000:0000:0000:0000:0009</span>:53 -&gt; <span class="entity ipv6" data-entity-type="ipv6" data-entity-value="2620:0106:6008:009b:00f0:0000:0000:0021">2620:0106:6008:009b:00f0:0000:0000:0021</span>:57239</div></div>
EOF
        entities    => [
            { type    => 'ipv6', value   => '2001:489a:2202:2000:0000:0000:0000:0009', },
            { type    => 'ipv6', value   => '2620:0106:6008:009b:00f0:0000:0000:0021', },
        ],
    },
    {
        name    => 'leading ip4:',
        source  => <<EOF,
<html><p>ip4:65.38.177[.]13</p></html>
EOF
        plain   => <<EOF,
   ip4:65.38.177.13
EOF
        flair   => <<'EOF',
<div><p>ip4:<span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="65.38.177.13">65.38.177.13</span></div>
EOF
        entities    => [
            { 'type'    => 'ipaddr', 'value' => '65.38.177.13' }
        ],
    },

);

our @uuid1_tests = (
    {
        name => 'uuid1-1',
        source      => <<'EOF',
d0229d40-1274-11e8-a427-3d01d7fc9aea
EOF
        plain       => <<'EOF',
d0229d40-1274-11e8-a427-3d01d7fc9aea
EOF
        flair       => <<'EOF',
<div><span class="entity uuid1" data-entity-type="uuid1" data-entity-value="d0229d40-1274-11e8-a427-3d01d7fc9aea">d0229d40-1274-11e8-a427-3d01d7fc9aea</span>
</div>
EOF
        entities    => [
            { value   => 'd0229d40-1274-11e8-a427-3d01d7fc9aea', type    => 'uuid1', }
        ],
        userdef => [],
    },
);

our @messageid_tests = (
    {
        name    => "message_id_1",
        source      => <<'EOF',
&lt;CAEr1S5-HuU1MjnUQtqT6Ri-i2ZaYcTm_+cjf6mkmOgwGJHjPJA@mail.gmail.com&gt;
EOF
        plain       => <<'EOF',
<CAEr1S5-HuU1MjnUQtqT6Ri-i2ZaYcTm_+cjf6mkmOgwGJHjPJA@mail.gmail.com>
EOF
    flair           => <<'EOF',
<div><span class="entity message_id" data-entity-type="message_id" data-entity-value="&lt;caer1s5-huu1mjnuqtqt6ri-i2zayctm_+cjf6mkmogwgjhjpja@mail.gmail.com&gt;">&lt;CAEr1S5-HuU1MjnUQtqT6Ri-i2ZaYcTm_+cjf6mkmOgwGJHjPJA@mail.gmail.com&gt;</span>
</div>
EOF
        entities    => [
            { value   => '<caer1s5-huu1mjnuqtqt6ri-i2zayctm_+cjf6mkmogwgjhjpja@mail.gmail.com>', type    => 'message_id', }
        ],
        userdef => [],
    },
    {
        name    => "not_message_id_1",
        source      => <<'EOF',
<div>
<body>
Foo
</body>
</div>
EOF
        plain       => <<'EOF',
 Foo
EOF
    flair           => <<'EOF',
<div><div></div>
Foo
</div>
EOF
    entities    => [
    ],
    userdef => [],
    debug   => 1,
    },
    {
        name    => "not_message_id_2",
        source      => <<'EOF',
&lt;div&gt;
&lt;body&gt;
Foo
&lt;/body&gt;
&lt;/div&gt;
EOF
        plain       => <<'EOF',
<div> <body> Foo </body> </div>
EOF
    flair           => <<'EOF',
<div>&lt;div&gt;
&lt;body&gt;
Foo
&lt;/body&gt;
&lt;/div&gt;
</div>
EOF
    entities    => [
    ],
    userdef => [],
    debug   => 1,
    },
    {
        testname    => "not_message_id_3",
        testgroup   => "message_id",
        testnumber  => 40,
        source      => <<'EOF',
EOF
        plain       => <<'EOF',
EOF
    flair           => <<'EOF',
<div></div>
EOF
    entities    => [
    ],
    userdef => [],
    debug   => 1,
    },
);

our @clsid_tests = (
    {
        name    => "Microsoft CLSID",
        source      => <<'EOF',
"{F20DA720-C02F-11CE-927B-0800095AE340}": "OLE Package Object",
EOF
        plain       => <<'EOF',
"{F20DA720-C02F-11CE-927B-0800095AE340}": "OLE Package Object",
EOF
        flair       => <<'EOF',
<div>&quot;{<span class="entity clsid" data-entity-type="clsid" data-entity-value="f20da720-c02f-11ce-927b-0800095ae340">F20DA720-C02F-11CE-927B-0800095AE340</span>}&quot;: &quot;OLE Package Object&quot;,
</div>
EOF
        entities    => [
            { value => "f20da720-c02f-11ce-927b-0800095ae340", type  => "clsid", },
        ],
        userdef => [],
    },
);


1;
