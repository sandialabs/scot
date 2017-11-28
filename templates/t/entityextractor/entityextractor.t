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
my $source   = <<EOF;
<html>  Attack originated from <a href="www.attacker.com/asdf">www.attacker.com/asdf</a> </html>
EOF
my $html   = '';
my $plain = '';
my $extractor   = Scot::Util::EntityExtractor->new({log=>$log});
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

$source = q|<html><img src="http://www.watermelon.com/_assets/images/features/fiber-cereal.jpg"></img>192.168.0.1</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><p><img src="http://www.watermelon.com/_assets/images/features/fiber-cereal.jpg" /><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span></body></html>',
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
cmp_deeply ( $entity_href, $expected_href, "doesn't mistake obj oriented code fro a domain as long as a parenthese is attached");

$source = q|<html>code like this: out.append could fool this.</html>|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
    'flair' => '<html><head></head><body><p>code like this: <span class="entity domain" data-entity-type="domain" data-entity-value="out.append">out.append</span> could fool this.</body></html>',
    'text' => 'code like this: out.append could fool this.',
    'entities' => [{value=>"out.append", type=>"domain"}],
};
cmp_deeply ( $entity_href, $expected_href, "does mistake obj oriented code fo a domain, which is OK"); 


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

$source = q|
<html><head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body>
<p>&nbsp;</p>
<p><strong><font color="red">Sem12 Database&nbsp; --All SQN SEP 12 
Clients--</font></strong></p>
<p><table border="1"><thead><tr style="font-weight:bold"><th>APP_Name</th><th>APPLICATION_PATH</th><th>APPZ_Description</th><th>CHECKSUM</th><th>COMPUTER_NAME</th><th>Computer_Time_Stamp</th><th>CURRENT_LOGIN_DOMAIN</th><th>CURRENT_LOGIN_USER</th><th>FILE_SIZE</th><th>LAST_ACCESS_TIME</th><th>LAST_MODIFY_TIME</th><th>OPERATION_SYSTEM</th><th>SEM_Computer_Time_Stamp</th><th>SERVICE_PACK</th><th>TIME_STAMP</th><th>TIME_STAMP_SEMAPPLICATION</th><th>VERSION</th></tr></thead><tbody><tr><td>microsoft.datawarehouse.resources.dll</td><td>c:\program files (x86)\microsoft office\office15\addins\powerpivot excel add-in\tr\</td><td>Microsoft.DataWarehouse</td><td>48BDCA4A5C014B1F8605E23D485D8DC0</td><td>DAASE320W7</td><td>1441924911470</td><td>SQN.watermelon.GOV</td><td>jnirsch</td><td>319136</td><td>0</td><td>1414584654000</td><td>Windows 7 Enterprise Edition</td><td>1441964684085</td><td>Service Pack 1</td><td>1441924911470</td><td>12/9/1985 10:41:51 PM</td><td>11.0.2830.24 ((BI_O15_OfficeBox-CU).141015-1558 )</td></tr><tr><td>jeffretires.exe</td><td>c:\users\dmkeiss\appdata\local\temp\temp2_jeffretires.zip\</td><td></td><td>0A0FFD00CD32B2F540114245CFED488E</td><td>S964892</td><td>1441921551573</td><td>SQN.watermelon.GOV</td><td>dmkeiss</td><td>28672</td><td>130863945340120000</td><td>1441920578900</td><td>Windows 7 Enterprise Edition</td><td>1441963983746</td><td>Service Pack 1</td><td>1441921551573</td><td>12/9/1985 9:45:51 PM</td><td></td></tr></tbody></table></p>
<p><font color="lightgreen"></font>&nbsp;</p>
<p><font color="lightgreen">Sem12 Dev Database</font></p>
<p><table border="1"><thead><tr style="font-weight:bold"><th>APP_Name</th><th>APPLICATION_PATH</th><th>APPZ_Description</th><th>CHECKSUM</th><th>COMPUTER_NAME</th><th>Computer_Time_Stamp</th><th>CURRENT_LOGIN_DOMAIN</th><th>CURRENT_LOGIN_USER</th><th>FILE_SIZE</th><th>LAST_ACCESS_TIME</th><th>LAST_MODIFY_TIME</th><th>OPERATION_SYSTEM</th><th>SEM_Computer_Time_Stamp</th><th>SERVICE_PACK</th><th>TIME_STAMP</th><th>TIME_STAMP_SEMAPPLICATION</th><th>VERSION</th></tr></thead><tbody></tbody></table></p>
<p>&nbsp;</p>
<p>&nbsp;</p></body></html>
|;
$entity_href    = $extractor->process_html($source);
$expected_href  = {
'flair' => '<html><head><meta content="text/html; charset=utf-8" http-equiv="Content-Type" /></head><body><p>&nbsp;<p><strong><font color="red">Sem12 Database&nbsp; --All SQN SEP 12 Clients--</font></strong><p><table border="1"><thead><tr style="font-weight:bold"><th>APP_Name</th><th>APPLICATION_PATH</th><th>APPZ_Description</th><th>CHECKSUM</th><th>COMPUTER_NAME</th><th>Computer_Time_Stamp</th><th>CURRENT_LOGIN_DOMAIN</th><th>CURRENT_LOGIN_USER</th><th>FILE_SIZE</th><th>LAST_ACCESS_TIME</th><th>LAST_MODIFY_TIME</th><th>OPERATION_SYSTEM</th><th>SEM_Computer_Time_Stamp</th><th>SERVICE_PACK</th><th>TIME_STAMP</th><th>TIME_STAMP_SEMAPPLICATION</th><th>VERSION</th></tr></thead><tbody><tr><td><span class="entity domain" data-entity-type="domain" data-entity-value="microsoft.datawarehouse.resources.dll">microsoft.<span class="entity domain" data-entity-type="domain" data-entity-value="datawarehouse.resources.dll">datawarehouse.<span class="entity domain" data-entity-type="domain" data-entity-value="resources.dll">resources.dll</span></span></span></td><td>c:\\program files (x86)\\microsoft office\\office15\\addins\\powerpivot excel add-in\\tr\\</td><td>Microsoft.DataWarehouse</td><td><span class="entity md5" data-entity-type="md5" data-entity-value="48BDCA4A5C014B1F8605E23D485D8DC0">48BDCA4A5C014B1F8605E23D485D8DC0</span></td><td>DAASE320W7</td><td>1441924911470</td><td><span class="entity domain" data-entity-type="domain" data-entity-value="SQN.watermelon.GOV">SQN.<span class="entity domain" data-entity-type="domain" data-entity-value="watermelon.GOV">watermelon.GOV</span></span></td><td>jnirsch</td><td>319136</td><td>0</td><td>1414584654000</td><td>Windows 7 Enterprise Edition</td><td>1441964684085</td><td>Service Pack 1</td><td>1441924911470</td><td>12/9/1985 10:41:51 PM</td><td>11.0.2830.24 ((BI_O15_OfficeBox-CU).141015-1558 )</td></tr><tr><td><span class="entity file" data-entity-type="file" data-entity-value="jeffretires.exe">jeffretires.exe</span></td><td>c:\\users\\dmkeiss\\appdata\\local\\temp\\<span class="entity file" data-entity-type="file" data-entity-value="temp2_jeffretires.zip">temp2_jeffretires.zip</span>\\</td><td></td><td><span class="entity md5" data-entity-type="md5" data-entity-value="0A0FFD00CD32B2F540114245CFED488E">0A0FFD00CD32B2F540114245CFED488E</span></td><td><span class="entity snumber" data-entity-type="snumber" data-entity-value="S964892">S964892</span></td><td>1441921551573</td><td><span class="entity domain" data-entity-type="domain" data-entity-value="SQN.watermelon.GOV">SQN.<span class="entity domain" data-entity-type="domain" data-entity-value="watermelon.GOV">watermelon.GOV</span></span></td><td>dmkeiss</td><td>28672</td><td>130863945340120000</td><td>1441920578900</td><td>Windows 7 Enterprise Edition</td><td>1441963983746</td><td>Service Pack 1</td><td>1441921551573</td><td>12/9/1985 9:45:51 PM</td><td></td></tr></tbody></table><p><font color="lightgreen"></font>&nbsp;<p><font color="lightgreen">Sem12 Dev Database</font><p><table border="1"><thead><tr style="font-weight:bold"><th>APP_Name</th><th>APPLICATION_PATH</th><th>APPZ_Description</th><th>CHECKSUM</th><th>COMPUTER_NAME</th><th>Computer_Time_Stamp</th><th>CURRENT_LOGIN_DOMAIN</th><th>CURRENT_LOGIN_USER</th><th>FILE_SIZE</th><th>LAST_ACCESS_TIME</th><th>LAST_MODIFY_TIME</th><th>OPERATION_SYSTEM</th><th>SEM_Computer_Time_Stamp</th><th>SERVICE_PACK</th><th>TIME_STAMP</th><th>TIME_STAMP_SEMAPPLICATION</th><th>VERSION</th></tr></thead><tbody></tbody></table><p>&nbsp;<p>&nbsp;</body></html>',
          'entities' => [
                          {
                            'type' => 'domain',
                            'value' => 'microsoft.datawarehouse.resources.dll'
                          },
                          {
                            'type' => 'domain',
                            'value' => 'datawarehouse.resources.dll'
                          },
                          {
                            'value' => 'resources.dll',
                            'type' => 'domain'
                          },
                          {
                            'value' => '48BDCA4A5C014B1F8605E23D485D8DC0',
                            'type' => 'md5'
                          },
                          {
                            'type' => 'domain',
                            'value' => 'SQN.watermelon.GOV'
                          },
                          {
                            'value' => 'watermelon.GOV',
                            'type' => 'domain'
                          },
                          {
                            'value' => 'jeffretires.exe',
                            'type' => 'file'
                          },
                          {
                            'type' => 'file',
                            'value' => 'temp2_jeffretires.zip'
                          },
                          {
                            'value' => '0A0FFD00CD32B2F540114245CFED488E',
                            'type' => 'md5'
                          },
                          {
                            'value' => 'S964892',
                            'type' => 'snumber'
                          },
                          {
                            'value' => 'SQN.watermelon.GOV',
                            'type' => 'domain'
                          }
                        ],
};
delete $entity_href->{text};
cmp_deeply ( $entity_href, $expected_href, "real life 1 passed");

$source = q{
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html xmlns="http://www.w3.org/1999/xhtml"><head>
 <meta http-equiv="Content-Type" content="text/html; charset=utf-8"> </head> <body style="font-size: 14px; font-family: helvetica, arial, sans-serif; padding: 20px 0; margin: 0; color: #333;"> <div style="margin-top: 10px; padding-top: 20px; border-top: 1px solid #ccc;"></div> <a href="https://mqrpx.watermelon.com:8000/app/search/@go?sid=scheduler__axq__search__RMD52d4de19f8b7990d9_at_1441976400_91131" style=" text-decoration: none; margin: 0 20px; color: #5379AF;">View results in Splunk</a> <div style="margin:0"> <div style="overflow: auto; width: 100%;"> <table cellpadding="0" cellspacing="0" border="0" class="results" style="margin: 20px;"> <tbody> <tr> <th style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">_time</th> <th style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">quarantined</th> <th style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">HREF</th> <th style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">MAILSUBJECT</th> <th style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">MAIL_FROM</th> <th style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">X_IronPort_RCPT_FROM</th> <th style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">MAIL_TO</th> <th style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">X_IronPort_RCPT_ALL</th> <th style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">MESSAGE_ID</th> <th style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">docid</th> </tr> <tr valign="top"> <td style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">Fri Sep 11 06:57:39 2015</td> <td style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">False</td> <td style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">http://members.tcg.org/apps/org/workgroup/tpmwg/download.php/26487/latest/TPM2_SendObject_TCG_150901.zip http://members.tcg.org/apps/org/workgroup/tpmwg/document.php?document_id=26487</td> <td style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">RE: [tpmwg] Groups - TPM2_SendObject-Slides uploaded</td> <td style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">david.challener@jhuapl.edu</td> <td style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">tpmwg-return-14496-tqqqqt=watermelon.com@tcg.org</td> <td style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">tpmwg@tcg.org andreas.fuchs@sit.fraunhofer.de tqqqqt@watermelon.com monty.wiseman@intel.com</td> <td style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">tqqqqt@watermelon.com</td> <td style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">1a9fecc1a3724327b294d91c461d20b0@aplex05.dom1.jhuapl.edu</td> <td style="text-align: left; padding: 4px 8px; border-bottom: 1px dotted #ccc;">71871d57f1d623fc21b9f3f36c9c245d</td> </tr> </tbody> </table> </div> </div> <div style="margin-top: 10px; border-top: 1px solid #ccc;"></div> <p style="margin: 20px; font-size: 11px; color: #999;">If you believe you've received this email in error, please see your Splunk administrator.<br><br>splunk &gt; the engine for machine data</p> </body> </html>};

$entity_href    = $extractor->process_html($source);

done_testing();

print Dumper($entity_href);


exit 0;

 # debug
 # print Dumper($t->tx->res->json), "\n";
 # done_testing();
 # exit 0;
