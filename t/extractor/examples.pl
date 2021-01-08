@data   = (
    # {
    #   testname => x,
    #   testgroup => y,
    #   testnumber => z,
    #   source  => "text",
    #   entities    => [ expected entities ],
    #   plain   => "expected plain text",
    #   flair   => "expected flaired text",
    
    {
        testname    => 'scot-7397',
        testgroup   => 'domain',
        testnumber  => 1,
        source  => <<EOF,
<html>
https://cbase.som.sunysb.edu/soap/bss.cfm
</html>
EOF
        plain   => <<EOF,
 https://cbase.som.sunysb.edu/soap/bss.cfm
EOF
        flair   => <<EOF,
<div>
https://<span class="entity domain" data-entity-type="domain" data-entity-value="cbase.som.sunysb.edu">cbase.som.sunysb.edu</span>/soap/<span class="entity file" data-entity-type="file" data-entity-value="bss.cfm">bss.cfm</span>
</div>
EOF
        entities    => [
            {
                type    => "domain",
                value   => "cbase.som.sunysb.edu",
            },
            {
                type    => "file",
                value   => "bss.cfm",
            },
        ],
    },

    {
        testname    => "google plain",
        testgroup   => "domain",
        testnumber  => 2,
        source  => 'www.google.com',
        flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span></div>',
        plain   => 'www.google.com',
        entities  => [ { type  => 'domain', value => 'www.google.com' } ],
    },

    {
        testname    => "google obsfucated 1",
        testgroup   => "domain",
        testnumber  => 3,
        source  => 'www(.)google(.)com',
        flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span></div>',
        plain   => 'www.google.com',
        entities  => [ { type  => 'domain', value => 'www.google.com' } ],
    },

    {
        testname    => "google obsfucated 2",
        testgroup   => "domain",
        testnumber  => 4,
        source  => 'www[.]google[.]com',
        flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span></div>',
        plain   => 'www.google.com',
        entities  => [ { type  => 'domain', value => 'www.google.com' } ],
    },

    {
        testname    => "google obsfucated 3",
        testgroup   => "domain",
        testnumber  => 5,
        source  => 'www{.}google{.}com',
        flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span></div>',
        plain   => 'www.google.com',
        entities  => [ { type  => 'domain', value => 'www.google.com' } ],
    },

    {
        testname    => "google obsfucated 4",
        testgroup   => "domain",
        testnumber  => 6,
        source  => 'https://cbase(.)som[.]sunysb{.}edu/foo/bar',
        flair   => '<div>https://<span class="entity domain" data-entity-type="domain" data-entity-value="cbase.som.sunysb.edu">cbase.som.sunysb.edu</span>/foo/bar</div>',
        plain   => 'https://cbase.som.sunysb.edu/foo/bar',
        entities  => [ { type => 'domain', value => 'cbase.som.sunysb.edu' } ],
    },

    {
        testname    => "google obsfucated 4",
        testgroup   => "domain",
        testnumber  => 7,
        source  => 'https://support.online',
        flair   => '<div>https://<span class="entity domain" data-entity-type="domain" data-entity-value="support.online">support.online</span></div>',
        plain   => 'https://support.online',
        entities  => [
            { type=> 'domain', value => "support.online" },
        ],
    },
    {
        testname    => "invalid dotted hex",
        testgroup   => "domain",
        testnumber  => 8,
        source  => '8a.93.8c.99.8d.61.62.86.97.88.86.91.91.8e.4e.97.8a.99',
        flair   => '<div>8a.93.8c.99.8d.61.62.86.97.88.86.91.91.8e.4e.97.8a.99</div>',
        plain   => '8a.93.8c.99.8d.61.62.86.97.88.86.91.91.8e.4e.97.8a.99',
        entities  => [],
    },

    ## 
    ## test entities within an html table
    ##

    {
        testname    => "entities in html table",
        testgroup   => "basic",
        testnumber  => 9,
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
            {
                'type' => 'ipaddr',
                'value' => '10.10.1.2'
            },
            {
                'value' => 'todd@watermelon.gov',
                'type' => 'email'
            },
            {
                value   => 'watermelon.gov',
                type    => 'domain',
            },
        ],

    },

    {
        testname    => "ip addr 1",
        testgroup   => "ipaddr",
        testnumber  => 10,
        source  => <<'EOF',
<html>192.168.0.1 is the IP address of your router! Exclaimed the investigative computer scientist</html>
EOF
        plain   => <<'EOF',
192.168.0.1 is the IP address of your router! Exclaimed the investigative
   computer scientist
EOF
        flair   => <<'EOF',
<div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span> is the IP address of your router! Exclaimed the investigative computer scientist</div>
EOF
        entities    => [
            {
                'value' => '192.168.0.1',
                'type' => 'ipaddr'
            }
        ],
    },
    
    {
        testname    => "ip addr 2",
        testgroup   => "ipaddr",
        testnumber  => 11,
        source  => <<'EOF',
<html>Lets make sure that the router at <em>192</em>.<em>168</em>.<em>0</em>.<em>1</em> is still working</html>
EOF
        plain   => <<'EOF',
Lets make sure that the router at 192.168.0.1 is still working
EOF
        flair   => <<'EOF',
<div>Lets make sure that the router at <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span> is still working</div>
EOF
        entities    => [
            {
                'value' => '192.168.0.1',
                'type' => 'ipaddr'
            }
        ],
    },
    
    {
        testname    => "ip addr 3",
        testgroup   => "ipaddr",
        testnumber  => 12,
        source  => <<'EOF',
<html>Test with ip ending a sentance 10.10.1.3. Next sentance</html>
EOF
        plain   => <<'EOF',
Test with ip ending a sentance 10.10.1.3. Next sentance
EOF
        flair   => <<'EOF',
<div>Test with ip ending a sentance <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.1.3">10.10.1.3</span>. Next sentance</div>
EOF
        entities    => [
            {
                'value' => '10.10.1.3',
                'type' => 'ipaddr'
            }
        ],
    },

    {
        testname    => "ip addr 4",
        testgroup   => "ipaddr",
        testnumber  => 13,
        source  => <<'EOF',
<html>Test with ip ending a sentance 10.10.1.3.a. Next sentance</html>
EOF
        plain   => <<'EOF',
Test with ip ending a sentance 10.10.1.3.a. Next sentance
EOF
        flair   => <<'EOF',
<div>Test with ip ending a sentance 10.10.1.3.a. Next sentance</div>
EOF
        entities    => [
        ],
    },

    {
        testname    => "ip addr obsfucated",
        testgroup   => "ipaddr",
        testnumber  => 14,
        source  => <<'EOF',
List of weird ipaddres:
<table>
<tr>
    <th>Host</th><th>IPaddr</th>
</tr>
<tr>
    <td>foobar</td><td>10{.}10{.}10{.}1</td>
</tr>
<tr>
    <td>boombaz</td><td>20[.]20[.]20[.]20</td>
</tr>
</table>
EOF
        plain   => <<'EOF',
List of weird ipaddres:

   Host

   IPaddr

   foobar

   10.10.10.1

   boombaz

   20.20.20.20
EOF
        flair   => <<'EOF',
<div>List of weird ipaddres:
<table><tr><th>Host</th><th>IPaddr</th></tr><tr><td>foobar</td><td><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span></td></tr><tr><td>boombaz</td><td><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="20.20.20.20">20.20.20.20</span></td></tr></table></div>
EOF
        entities    => [
            {
            'value' => '10.10.10.1',
            'type' => 'ipaddr'
            },
            {
            'type' => 'ipaddr',
            'value' => '20.20.20.20'
            }
        ],
    },

    {
        testname    => "ip obsfucated 2",
        testgroup   => "ipaddr",
        testnumber  => 15,
        source  => <<'EOF',
<html>
<ul>list of ip obfuscations:
    <li>10[.]10[.]10[.]10</li>
    <li>10{.}10{.}10{.}10</li>
    <li>10(.)10(.)10(.)10</li>
</html>
EOF
        plain   => <<'EOF',
     list of ip obfuscations: * 10.10.10.10

     * 10.10.10.10

     * 10.10.10.10
EOF
        flair   => <<'EOF',
<div><ul>list of ip obfuscations:
    <li><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.10">10.10.10.10</span><li><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.10">10.10.10.10</span><li><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.10">10.10.10.10</span></ul></div>
EOF
        entities    => [
            {
            'value' => '10.10.10.10',
            'type' => 'ipaddr'
            },
            {
            'value' => '10.10.10.10',
            'type' => 'ipaddr'
            },
            {
            'value' => '10.10.10.10',
            'type' => 'ipaddr'
            },
        ],
    },
        
    ##
    ## email tests
    ## 

    {
        testname    => "email",
        testgroup   => "email",
        testnumber  => 16,
        source  => << 'EOF',
<div>scot-dev@watermelon.gov
mailman-bounces@trixios.org</div>
EOF
        plain   => << 'EOF',
scot-dev@watermelon.gov mailman-bounces@trixios.org
EOF
        flair   => << 'EOF',
<div><div><span class="entity email" data-entity-type="email" data-entity-value="scot-dev@watermelon.gov">scot-dev@<span class="entity domain" data-entity-type="domain" data-entity-value="watermelon.gov">watermelon.gov</span></span>
<span class="entity email" data-entity-type="email" data-entity-value="mailman-bounces@trixios.org">mailman-bounces@<span class="entity domain" data-entity-type="domain" data-entity-value="trixios.org">trixios.org</span></span></div></div>
EOF
        entities    => [
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
        ],
    },

    {
        testname    => "domain with numeric component",
        testgroup   => "domain",
        testnumber  => 16,
        source  => 'foo.10.com',
        flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="foo.10.com">foo.10.com</span></div>',
        plain   => 'foo.10.com',
        entities  => [ { type  => 'domain', value => 'foo.10.com' } ],
    },

    {
        testname    => "weird error",
        testgroup   => "basic",
        testnumber  => 17,
        source  => <<'EOF',
Added the following to the blocklist:<br><br><pre>foo foundersomaha.net  meaningless <br>externalbatterycase.com some other post text</pre>
<p>nothing here</p>
<div>
IP addr time:
<em>10</em>.<em>10</em>.<em>10</em>.<em>10</em>
123.123.123.123
</div>
EOF
        plain   => <<'EOF',
Added the following to the blocklist:

   foo       foundersomaha.net           meaningless    
   externalbatterycase.com       some       other       post       text

   nothing here

   IP addr time: 10.10.10.10 123.123.123.123
EOF
        flair   => <<'EOF',
<div>Added the following to the blocklist:<br /><br /><pre>foo <span class="entity domain" data-entity-type="domain" data-entity-value="foundersomaha.net">foundersomaha.net</span>  meaningless <br /><span class="entity domain" data-entity-type="domain" data-entity-value="externalbatterycase.com">externalbatterycase.com</span> some other post text</pre><p>nothing here<div>
IP addr time:
<span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.10">10.10.10.10</span>
<span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="123.123.123.123">123.123.123.123</span>
</div></div>
EOF
        entities    => [
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
        ],
    },

    {
        testname    => "broken html",
        testgroup   => "basic",
        testnumber  => 18,
        source  => <<'EOF',
<html><script>alert(9)</script>192.168.0.1</html>
EOF
        plain   => <<'EOF',
192.168.0.1
EOF
        flair   => <<'EOF',
<div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span></div>
EOF
        entities    => [
            { 
                value   => '192.168.0.1',
                type    => 'ipaddr',
            }
        ],
    },

    {
        testname    => "anchor discrimination",
        testgroup   => "basic",
        testnumber  => 19,
        source  => <<'EOF',
<html>The attack <a href="www.attacker.com/asdf">www.attacker.com/asdf</a>  foo</html>
EOF
        plain   => <<'EOF',
The attack www.attacker.com/asdf foo
EOF
        flair   => <<'EOF',
<div>The attack <a href="www.attacker.com/asdf"><span class="entity domain" data-entity-type="domain" data-entity-value="www.attacker.com">www.attacker.com</span>/asdf</a>  foo</div>
EOF
        entities    => [
            {
                'value' => 'www.attacker.com',
                'type'  => 'domain',
            },
        ],
    },

    {
        testname    => "id domain",
        testgroup   => "domain",
        testnumber  => 20,
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
            {
                value   => 'paziapm.co.id',
                type    => 'domain',
            },
        ],
    },
    
    {
        testname    => "flair cve refs",
        testgroup   => "cve",
        testnumber  => 21,
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
            {
                value   => 'cve-2017-12345',
                type    => 'cve',
            },
        ],
    },

    {
        testname    => "underscore in entity",
        testgroup   => "basic",
        testnumber  => 22,
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
            {
                value   => 'todd_bruner@foo.com',
                type    => 'email',
            },
            {
                value   => 'foo.com',
                type    => 'domain',
            },
        ],
    },

    {
        testname    => "user defined 1",
        testgroup   => "userdef",
        testnumber  => 23,
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
            {
                value   => 'fuzzy foobar',
                type    => 'actor',
            }
        ],
    },

    {
        testname    => "user defined 2",
        testgroup   => "userdef",
        testnumber  => 24,
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
            {
                value   => '10.10.10.1',
                type    => 'ipaddr',
            }
        ],
        userdef     => [
            {
                value   => 'fuzzy foobar',
                type    => 'actor',
            }
        ],
    },

    {
        testname    => "user defined 3",
        testgroup   => "userdef",
        testnumber  => 24,
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
            {
                value   => 'fuzzy foobar',
                type    => 'threat_group',
            }
        ],
    },
    {
        testname    => "multiword 1",
        testgroup   => "multiword",
        testnumber  => 25,
        source      => <<'EOF',
<html>The quick brown fox jumped over the lazy dog</html>
EOF
        plain       => <<'EOF',
The quick brown fox jumped over the lazy dog
EOF
        flair       => <<'EOF',
<div>The quick <span class="entity actor" data-entity-type="actor" data-entity-value="brown fox">brown fox</span> jumped over the lazy dog</div>
EOF
        entities    => [
            {
                value   => 'brown fox',
                type    => 'actor',
            }
        ],
        userdef => [],
    },

    {
        testname    => "user defined entitytype 1",
        testgroup   => "multiword",
        testnumber  => 26,
        source      => <<'EOF',
<html>the group Testing Foo is at it again</html>
EOF
        plain       => <<'EOF',
the group Testing Foo is at it again
EOF
        flair       => <<'EOF',
<div>the group <span class="entity userdef-1" data-entity-type="userdef-1" data-entity-value="testing foo">Testing Foo</span> is at it again</div>
EOF
        entities    => [
            {
                value   => 'testing foo',
                type    => 'userdef-1',
            }
        ],
        userdef => [
        ],
    },
    {
        testname    => "LaikaBoss signature flair 1",
        testgroup   => "LaikaBoss",
        testnumber  => 27,
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
            {
                value   => 'yr:misc_google_amp_link_s75_1',
                type    => 'lbsig',
            }
        ],
        userdef => [
        ],
    },
    {
        testname    => "LaikaBoss signature flair 2",
        testgroup   => "LaikaBoss",
        testnumber  => 28,
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
            {
                value   => 'yr:misc_vbaproj_codepage_foreign_s63_1',
                type    => 'lbsig',
            }
        ],
        userdef => [
        ],
    },
    {
        testname    => "Email with Capitalization",
        testgroup   => "basic",
        testnumber  => 29,
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
            {
                'type' => 'ipaddr',
                'value' => '10.10.1.2'
            },
            {
                'value' => 'todd@watermelon.gov',
                'type' => 'email'
            },
            {
                value   => 'watermelon.gov',
                type    => 'domain',
            },
        ],

    },
    {
        testname    => "JRock fun with user def",
        testgroup   => "jcjaroc",
        testnumber  => 30,
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
        testname    => "cidr1",
        testgroup   => "cidr",
        testnumber  => 31,
        source      => <<'EOF',
10.10.10.0/30
EOF
        plain       => <<'EOF',
10.10.10.0/30
EOF
        flair       => <<'EOF',
<div><span class="entity cidr" data-entity-type="cidr" data-entity-value="10.10.10.0/30">10.10.10.0/30</span></div>
EOF
        entities    => [
            {
                value   => '10.10.10.0/30',
                type    => 'cidr',
            }
        ],
        userdef => [
        ],
    },
    {
        testname    => "file1",
        testgroup   => "filenames",
        testnumber  => 32,
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
        testname    => 'ipv6-1',
        testgroup   => 'ipv6',
        testnumber  => 33,
        source      => <<'EOF',
1762:0:0:0:0:B03:1:AF18
EOF
        plain       => <<'EOF',
1762:0:0:0:0:B03:1:AF18
EOF
        flair       => <<'EOF',
<div><span class="entity ipv6" data-entity-type="ipv6" data-entity-value="1762:0:0:0:0:b03:1:af18">1762:0:0:0:0:B03:1:AF18</span></div>
EOF
        entities    => [
            {
                value   => '1762:0:0:0:0:b03:1:af18',
                type    => 'ipv6',
            }
        ],
        userdef => [],
    },
    {
        testname    => 'ipv6-1',
        testgroup   => 'ipv6',
        testnumber  => 33,
        source      => <<'EOF',
1762::b03:1:af18
EOF
        plain       => <<'EOF',
1762::b03:1:af18
EOF
        flair       => <<'EOF',
<div><span class="entity ipv6" data-entity-type="ipv6" data-entity-value="1762::b03:1:af18">1762::b03:1:af18</span></div>
EOF
        entities    => [
            {
                value   => '1762::b03:1:af18',
                type    => 'ipv6',
            }
        ],
        userdef => [],
    },
    {
        testname    => 'ipv6-3',
        testgroup   => 'ipv6',
        testnumber  => 35,
        source      => <<'EOF',
2001:41d0:2:9d17::
EOF
        plain       => <<'EOF',
2001:41d0:2:9d17::
EOF
        flair       => <<'EOF',
<div><span class="entity ipv6" data-entity-type="ipv6" data-entity-value="2001:41d0:2:9d17::">2001:41d0:2:9d17::</span></div>
EOF
        entities    => [
            {
                value   => '2001:41d0:2:9d17::',
                type    => 'ipv6',
            }
        ],
        userdef => [],
    },
    {
        testname    => 'uuid1-1',
        testgroup   => 'uuid1',
        testnumber  => 35,
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
            {
                value   => 'd0229d40-1274-11e8-a427-3d01d7fc9aea',
                type    => 'uuid1',
            }
        ],
        userdef => [],
    },

    {
        testname    => "email",
        testgroup   => "email",
        testnumber  => 36,
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
            {
                'value' => 'thedomain.biz',
                'type' => 'domain'
            },
            {
                'value' => 'user@thedomain.biz',
                'type' => 'email'
            },
        ],
    },

    {
        testname    => "file2",
        testgroup   => "filenames",
        testnumber  => 37,
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
            {
                value   => 'haxor.py',
                type    => 'file',
            }
    ],
    userdef => [],
    },
    {
        testname    => "message_id_1",
        testgroup   => "message_id",
        testnumber  => 38,
        source      => <<'EOF',
&lt;CAEr1S5-HuU1MjnUQtqT6Ri-i2ZaYcTm_+cjf6mkmOgwGJHjPJA@mail.gmail.com&gt;
EOF
        plain       => <<'EOF',
<CAEr1S5-HuU1MjnUQtqT6Ri-i2ZaYcTm_+cjf6mkmOgwGJHjPJA@mail.gmail.com>
EOF
    flair           => <<'EOF',
<div><span class="entity message_id" data-entity-type="message_id" data-entity-value="&lt;caer1s5-huu1mjnuqtqt6ri-i2zayctm_+cjf6mkmogwgjhjpja@mail.gmail.com&gt;">&lt;CAEr1S5-HuU1MjnUQtqT6Ri-i2ZaYcTm_+cjf6mkmOgwGJHjPJA@mail.gmail.com&gt;</span></div>
EOF
    entities    => [
            {
                value   => '<caer1s5-huu1mjnuqtqt6ri-i2zayctm_+cjf6mkmogwgjhjpja@mail.gmail.com>',
                type    => 'message_id',
            }
    ],
    userdef => [],
    debug   => 1,
    },
    {
        testname    => "not_message_id_1",
        testgroup   => "message_id",
        testnumber  => 39,
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
        testname    => "not_message_id_2",
        testgroup   => "message_id",
        testnumber  => 40,
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
    {
        testname    => "SLIMHTTP/1.1",
        testgroup   => "userdef",
        testnumber  => 41,
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
            {
                value   => 'slimhttp/1.1',
                type    => 'user_agent',
            }
    ],
    userdef => [],
    debug   => 0,
    },
    {
        testname    => "SRS Test One",
        testgroup   => "SRS",
        testnumber  => 42,
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
            {
                type    => "SRStestTwo",
                value   => "a129.5.5.5",
            },
            {
                type    => "SRStestTwo",
                value   => "a129.3.3.3",
            },
            {
                type    => "SRStestOne",
                value   => "testing123",
            }
    ],
    userdef => [],
    debug   => 0,
    },
    {
        testname    => "event 14246 ipv6 problem",
        testgroup   => "ipv6",
        testnumber  => 43,
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
                {
                    type    => "domain",
                    value   => "bn6pr27mb2539.namprd13.prod.poutlook.org",
                },
                {
                    type    => "ipv6",
                    value   => "2603:10b6:404:129::18",
                },
        ],
        userdef => [],
        debug   => 1,
    },
    {
        testname    => "SRS Test Two",
        testgroup   => "SRS",
        testnumber  => 42,
        source      => <<'EOF',
<div>A129.5.5.5 &nbsp;A129.3.3.3&nbsp;TESTING123</div>
EOF
        plain       => "A129.5.5.5 ".chr(160)."A129.3.3.3".chr(160)."TESTING123",
        flair        => <<'EOF',
<div><div><span class="entity SRStestTwo" data-entity-type="SRStestTwo" data-entity-value="a129.5.5.5">A129.5.5.5</span> &nbsp;<span class="entity SRStestTwo" data-entity-type="SRStestTwo" data-entity-value="a129.3.3.3">A129.3.3.3</span>&nbsp;<span class="entity SRStestOne" data-entity-type="SRStestOne" data-entity-value="testing123">TESTING123</span></div></div>
EOF
    entities    => [
            {
                type    => "SRStestTwo",
                value   => "a129.5.5.5",
            },
            {
                type    => "SRStestTwo",
                value   => "a129.3.3.3",
            },
            {
                type    => "SRStestOne",
                value   => "testing123",
            }
    ],
    userdef => [],
    debug   => 0,
    },
    {
        testname    => "Angle brackets suck part 2",
        testgroup   => "anglebrackets",
        testnumber  => 43,
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
    {
        testname    => "puny code 1",
        testgroup   => "punycode",
        testnumber  => 44,
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
            {
                value   => 'foo.xn--p1ai',
                type    => 'domain',
            },
        ],
        userdef => [],
        debug   => 1,
    },
    {
        testname    => "puny code 2",
        testgroup   => "punycode",
        testnumber  => 45,
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
            {
                value   => 'xn--clapcibic1.xn--p1ai',
                type    => 'domain',
            },
        ],
        userdef => [],
        debug   => 1,
    },
    {
        testname    => "email with =",
        testgroup   => "email",
        testnumber  => 46,
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
            {
                value   => 'email.followmyhealth.com',
                type    => 'domain',
            },
            {
                value   => 'bounces+182497-1c5d-xxxx=watermelon.edu@email.followmyhealth.com',
                type    => 'email',
            },
        ],
        userdef => [],
        debug   => 1,
    },
    {
        testname    => "Microsoft CLSID",
        testgroup   => "clsid",
        testnumber  => 47,
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
            {
                value => "f20da720-c02f-11ce-927b-0800095ae340",
                type  => "clsid",
            },
        ],
        userdef => [],
        debug   => 1,
    },
    {
        testname    => "false ipv6",
        testgroup   => "ipaddr",
        testnumber  => 48,
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
        testname    => "filename fail",
        testgroup   => "file",
        testnumber  => 49,
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
            {
                value   => 'pgas_rslts.cfm',
                type    => 'file',
            },
        ],
        userdef => [],
        debug   => 1,
    },
    {
        testname    => 'http[s] urls',
        testgroup   => 'domain',
        testnumber  => 1,
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
#    {
#        testname    => 'newish domain name',
#        testgroup   => 'domain',
#        testnumber  => 2,
#        source  => <<EOF,
#<html>
#    <div>
#        <p>gov.eg</p>
#    </div>
#</html>
#EOF
#        plain   => <<EOF,
#   gov.eg
#EOF
#        flair   => <<EOF,
#<div><div><p><span class="entity domain" data-entity-type="domain" data-entity-value="gov.eg">gov.eg</span></div></div>
#EOF
#        entities    => [
#            {
#                type    => "domain",
#                value   => "gov.eg",
#            },
#        ],
#    },
    {
        testname    => 'semi obsfucted ip addr',
        testgroup   => 'ipaddr',
        testnumber  => 2,
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
            {
                type    => "ipaddr",
                value   => "10.126.188.212",
            },
        ],
    },
    {
        testname    => 'semi obsfucted cidr addr',
        testgroup   => 'ipaddr',
        testnumber  => 2,
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
            {
                type    => "cidr",
                value   => "10.126.188.212/2",
            },
        ],
    },
    {
        testname    => 'suricata ipv6 with port',
        testgroup   => 'ipaddr',
        testnumber  => 2222,
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
            {
                type    => 'ipv6',
                value   => '2001:489a:2202:2000:0000:0000:0000:0009',
            },
            {
                type    => 'ipv6',
                value   => '2620:0106:6008:009b:00f0:0000:0000:0021',
            },
        ],
    },
);
