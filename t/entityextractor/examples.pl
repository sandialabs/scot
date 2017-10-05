%examples   = (
    # testname => {
    #   source  => "text",
    #   entities    => [ expected entities ],
    #   plain   => "expected plain text",
    #   flair   => "expected flaired text",
    
    '100'   => {
        'scot-7397' => {
            source  => <<EOF,
<html>
https://cbase.som.sunysb.edu/soap/bss.cfm
</html>
EOF
            plain   => <<EOF,
https://cbase.som.sunysb.edu/soap/bss.cfm
EOF
            flair   => <<EOF,
<div><br />https://<span class="entity domain" data-entity-type="domain" data-entity-value="cbase.som.sunysb.edu">cbase.som.sunysb.edu</span>/soap/bss.cfm<br /></div>
EOF
            entities    => [
                {
                    type    => "domain",
                    value   => "cbase.som.sunysb.edu",
                },
            ],
        },
        'google'    => {
            source  => 'www.google.com',
            flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span> </div>',
            plain   => 'www.google.com',
            entities  => [ { type  => 'domain', value => 'www.google.com' } ],
        },
        'google-obsf1' => {
            source  => 'www(.)google(.)com',
            flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span> </div>',
            plain   => 'www.google.com',
            entities  => [ { type  => 'domain', value => 'www.google.com' } ],
        },
        'google-obsf2' => {
            source  => 'www[.]google[.]com',
            flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span> </div>',
            plain   => 'www.google.com',
            entities  => [ { type  => 'domain', value => 'www.google.com' } ],
        },
        'google-obsf3' => {
            source  => 'www{.}google{.}com',
            flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span> </div>',
            plain   => 'www.google.com',
            entities  => [ { type  => 'domain', value => 'www.google.com' } ],
        },
        'objsf4'    => {
            source  => 'https://cbase(.)som[.]sunysb{.}edu/foo/bar',
            flair   => '<div>https://<span class="entity domain" data-entity-type="domain" data-entity-value="cbase.som.sunysb.edu">cbase.som.sunysb.edu</span>/foo/bar </div>',
            plain   => 'https://cbase.som.sunysb.edu/foo/bar',
            entities  => [ { type => 'domain', value => 'cbase.som.sunysb.edu' } ],
        },
        'invalid-domain'    => {
            source  => 'https://support.online',
            flair   => '<div>https://<span class="entity domain" data-entity-type="domain" data-entity-value="support.online">support.online</span> </div>',
            plain   => 'https://support.online',
            entities  => [
                { type=> 'domain', value => "support.online" },
            ],
        },
        'invalid-dotted-hex' => {
            source  => '8a.93.8c.99.8d.61.62.86.97.88.86.91.91.8e.4e.97.8a.99',
            flair   => '<div>8a.93.8c.99.8d.61.62.86.97.88.86.91.91.8e.4e.97.8a.99 </div>',
            plain   => '8a.93.8c.99.8d.61.62.86.97.88.86.91.91.8e.4e.97.8a.99',
            entities  => [],
        },
        
    }, # 100 series

    ## 
    ## test entities within an html table
    ##

    '200'   => {

        'table' => {
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
<div><table><tr><th>Ipaddr </th><th>email address </th></tr><tr><td><div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.1.2">10.10.1.2</span> </div> foo </td><td><span class="entity email" data-entity-type="email" data-entity-value="todd@watermelon.gov">todd@<span class="entity domain" data-entity-type="domain" data-entity-value="watermelon.gov">watermelon.gov</span></span> </td></tr></table></div>
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
        'ip1'   => {
            source  => <<'EOF',
<html>192.168.0.1 is the IP address of your router! Exclaimed the investigative computer scientist</html>
EOF
            plain   => <<'EOF',
92.168.0.1 is the IP address of your router! Exclaimed the
      investigative computer scientist
EOF
            flair   => <<'EOF',
<div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span> is the IP address of your router! Exclaimed the investigative computer scientist </div>
EOF
            entities    => [
                {
                    'value' => '192.168.0.1',
                    'type' => 'ipaddr'
                }
            ],
        },
        'ip2'   => {
            source  => <<'EOF',
<html>Lets make sure that the router at <em>192</em>.<em>168</em>.<em>0</em>.<em>1</em> is still working</html>
EOF
            plain   => <<'EOF',
Lets make sure that the router at 192.168.0.1 is still working
EOF
            flair   => <<'EOF',
<div>Lets make sure that the router at <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span> is still working </div>
EOF
            entities    => [
                {
                    'value' => '192.168.0.1',
                    'type' => 'ipaddr'
                }
            ],
        },
        'ip3'   => {
            source  => <<'EOF',
<html>Test with ip ending a sentance 10.10.1.3. Next sentance</html>
EOF
            plain   => <<'EOF',
Test with ip ending a sentance 10.10.1.3. Next sentance
EOF
            flair   => <<'EOF',
<div>Test with ip ending a sentance <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.1.3">10.10.1.3</span>. Next sentance </div>
EOF
            entities    => [
                {
                    'value' => '10.10.1.3',
                    'type' => 'ipaddr'
                }
            ],
        },
        'ip4'   => {
            source  => <<'EOF',
<html>Test with ip ending a sentance 10.10.1.3.a. Next sentance</html>
EOF
            plain   => <<'EOF',
Test with ip ending a sentance 10.10.1.3.a. Next sentance
EOF
            flair   => <<'EOF',
<div>Test with ip ending a sentance 10.10.1.3.a. Next sentance </div>
EOF
            entities    => [
            ],
        },
        'ip-obsfuscated'   => {
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
<div>List of weird ipaddres:<br /><table><tr><th>Host </th><th>IPaddr </th></tr><tr><td>foobar </td><td><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span> </td></tr><tr><td>boombaz </td><td><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="20.20.20.20">20.20.20.20</span> </td></tr></table></div>
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
        'ip-obsfuscated-2'   => {
            source  => <<'EOF',
<html>
    <ul>list of ip obfuscations:
        <li>10[.]10[.]10[.]10</li>
        <li>10{.}10{.}10{.}10</li>
        <li>10(.)10(.)10(.)10</li>
</html>
EOF
            plain   => <<'EOF',
list of ip obfuscations:
     * 10.10.10.10

     * 10.10.10.10

     * 10.10.10.10',
EOF
            flair   => <<'EOF',
<div><ul>list of ip obfuscations:<br /><li><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.10">10.10.10.10</span> <li><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.10">10.10.10.10</span> <li><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.10">10.10.10.10</span> </ul></div>
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
        
    }, # 200 series

    ##
    ## email tests
    ## 

    '300'   => {
        email   => {
            source  => << 'EOF',
<div>scot-dev@watermelon.gov
mailman-bounces@trixios.org</div>
EOF
            plain   => << 'EOF',
scot-dev@watermelon.gov
   mailman-bounces@trixios.org
EOF
            flair   => << 'EOF',
<div><div><span class="entity email" data-entity-type="email" data-entity-value="scot-dev@watermelon.gov">scot-dev@<span class="entity domain" data-entity-type="domain" data-entity-value="watermelon.gov">watermelon.gov</span></span><br /><span class="entity email" data-entity-type="email" data-entity-value="mailman-bounces@trixios.org">mailman-bounces@<span class="entity domain" data-entity-type="domain" data-entity-value="trixios.org">trixios.org</span></span> </div></div>
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
    }, # 300 series
    '400'   => {
        'domain-ip'   => {
            source  => 'foo.10.com',
            flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="foo.10.com">foo.10.com</span> </div>',
            plain   => 'foo.10.com',
            entities  => [ { type  => 'domain', value => 'foo.10.com' } ],
        },
    },
    '500'   => {
        'weird' => {
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

   foo       foundersomaha.net        meaningless
   externalbatterycase.com       some       other       post       text

   nothing here


   IP addr time:
   10.10.10.10
   123.123.123.123
EOF
            flair   => <<'EOF',
<div>Added the following to the blocklist: <br /><br /><pre>foo <span class="entity domain" data-entity-type="domain" data-entity-value="foundersomaha.net">foundersomaha.net</span>  meaningless <br /><span class="entity domain" data-entity-type="domain" data-entity-value="externalbatterycase.com">externalbatterycase.com</span> some other post text </pre><p>nothing here <div><br />IP addr time:<br /><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.10">10.10.10.10</span><br /><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="123.123.123.123">123.123.123.123</span><br /></div></div>
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
    },
    '600'   => {
        'broken_html'   => {
            source  => <<'EOF',
<html><script>alert(9)</script>192.168.0.1</html>
EOF
            plain   => <<'EOF',
192.168.0.1
EOF
            flair   => <<'EOF',
<div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span> </div>
EOF
            entities    => [
                { 
                    value   => '192.168.0.1',
                    type    => 'ipaddr',
                }
            ],
        },
    }, # 600 series
    '700'   => {
        'anchor'   => {
            source  => <<'EOF',
<html>The attack <a href="www.attacker.com/asdf">www.attacker.com/asdf</a>  foo</html>
EOF
            plain   => <<'EOF',
The attack www.attacker.com/asdf foo
EOF
            flair   => <<'EOF',
<div>The attack <a href="www.attacker.com/asdf"><span class="entity domain" data-entity-type="domain" data-entity-value="www.attacker.com">www.attacker.com</span>/asdf </a>  foo </div>
EOF
            entities    => [
                {
                    'value' => 'www.attacker.com',
                    'type'  => 'domain',
                },
            ],
        },
    }, # 700 series
    '800'   => {
        'id_domain'   => {
            source  => <<'EOF',
<html>paziapm.co.id</html>
EOF
            plain   => <<'EOF',
paziapm.co.id
EOF
            flair   => <<'EOF',
<div><span class="entity domain" data-entity-type="domain" data-entity-value="paziapm.co.id">paziapm.co.id</span> </div>
EOF
            entities    => [
                {
                    value   => 'paziapm.co.id',
                    type    => 'domain',
                },
            ],
        },
        'cve_flair' => {
            source  => <<'EOF',
<html>It was CVE-2017-12345</html>
EOF
            plain   => <<'EOF',
It was CVE-2017-12345
EOF
            flair   => <<'EOF',
<div>It was <span class="entity cve" data-entity-type="cve" data-entity-value="CVE-2017-12345">CVE-2017-12345</span> </div>
EOF
            entities    => [
                {
                    value   => 'cve-2017-12345',
                    type    => 'cve',
                },
            ],
        },
    },
);
