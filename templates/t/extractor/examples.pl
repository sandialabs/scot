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
https://<span class="entity domain" data-entity-type="domain" data-entity-value="cbase.som.sunysb.edu">cbase.som.sunysb.edu</span>/soap/bss.cfm
</div>
EOF
        entities    => [
            {
                type    => "domain",
                value   => "cbase.som.sunysb.edu",
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

);
