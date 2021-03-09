#!/usr/bin/env perl

use lib '../../../../lib';
use Scot::Email::Parser::Splunk;
use Scot::Env;
use Test::More;
use Test::Deep;
use Data::Dumper;

my $env = Scot::Env->new(
    config_file => '../../../../../Scot-Internal-Modules/etc/mailtest.cfg.pl'
);

my $parser  = Scot::Email::Parser::Splunk->new(
    env => $env
);

my $body_html = <<'EOF';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    </head>
    <body style="font-size: 14px; font-family: helvetica, arial, sans-serif; padding: 20px 0; margin: 0; color: #333;">
        <div style="margin: 0 20px;">The alert condition for '(FOO) emails that seem phishy (q=false)' was triggered.</div>
<table cellpadding="0" cellspacing="0" border="0" class="summary" style="margin: 20px;">
    <tbody>
        <tr>
            <th style="font-weight: normal; text-align: left; padding: 0 20px 10px 0;">Alert:</th>
            <td style="padding: 0 0 10px 0;"><a href="https://splunkit.watermelon.com/app/cyber/@go?dispatch_view=alert&amp;s=%2FservicesNS%2Fnobody%2Fcyber%2Fsaved%2Fsearches%2F%2528FOO%2529%2520emails%2520that%2520seem%2520phishy%2520%2528q%253Dfalse%2529" style=" text-decoration: none; margin: 0 40px 0 0; color: #006d9c;">(FOO) emails that seem phishy (q=false)</a></td>
        </tr>
        <tr>
            <th style="font-weight: normal; text-align: left; padding: 0 20px 10px 0;">Search String:</th>
            <td style="padding: 0 0 10px 0;">
            `email_lbdetect`  NOT x_feport_remotehost=&quot;phiest.nobe3.com&quot; summary=true [search sourcetype = MSExchange:2013:MessageTracking DELIVER [search `email_lbdetect` summary=true NOT quarantined=true  &quot;url_count&quot;&lt;4 earliest=-1h | dedup message_id | rex field=message_id &quot;&lt;?(?&lt;MESSAGE_ID&gt;[^&gt;]*)&quot; |table message_id] earliest=-1h |fields message_id |rename message_id as search |format] | eval message_id=replace('message_id', &quot;\\&lt;|\\&gt;&quot;,&quot;&quot;) | table index quarantined msg_direction datetime x_feport_rcpt_from mail_from x_feport_rcpt_all subject attachment{}.file_name url{} message_id</td>
        </tr>
    </tbody>
</table>


<div style="margin-top: 10px; padding-top: 20px; border-top: 1px solid #c3cbd4;"></div>
<div style="margin: 0 20px;">
    <a href="https://splunkit.watermelon.com/app/cyber/@go?sid=scheduler__foobar__cyber__RMD509a1f8c70cf0f0c0_at_1614701700_2182_A6F3AF33-1D3C-43C7-B086-A59444BA6A01" style=" text-decoration: none; color: #006d9c;">View results in Splunk</a>
</div>

<div style="margin:0">
    <div style="overflow: auto; width: 100%;">
        <table cellpadding="0" cellspacing="0" border="0" class="results" style="margin: 20px;">
            <tbody>
                
                <tr>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">index</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">quarantined</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">msg_direction</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">datetime</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">x_feport_rcpt_from</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">mail_from</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">x_feport_rcpt_all</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">subject</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">attachment{}.file_name</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">url{}</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">rootUID</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">message_id</th>
                </tr>
                    <tr valign="top">
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">email_lbdetect</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">false</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">incoming</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">2021-03-02 15:49:06Z</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">info@phyalinacting.com</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">&quot;Arts Conference&quot; &lt;info@phyalinacting.com&gt;</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">rblxx@watermelon.com</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">Conference: Call for Presentations</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;"></pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                    <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">https://www.youtube.com/user/artuniverseagency</pre>
                                    <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">https://www.facebook.com/iugte</pre>
                                    <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">http://www.performingartsconference.org</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">d0f83178-7b1e-11e1-8613-6151063c1f84</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">qpcm8d-0xfwax-m2@smtp-pxlsx.com</pre>
                        </td>
                    </tr>
                    <tr valign="top">
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">email_lbdetect</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">false</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">incoming</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">2021-03-02 15:49:06Z</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">info@phyalinacting.com</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">&quot;Arts Conference&quot; &lt;info@phyalacting.com&gt;</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">pbboche@watermelon.com</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">Call for Presentations: IUGTE Conference 2021</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;"></pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                    <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">https://www.youtube.com/user/artuniverseagency</pre>
                                    <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">https://www.facebook.com/iugte</pre>
                                    <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">http://www.performingartsconference.org</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">d164ce87-7b6e-11eb-be11-7b245233038c</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">qpcm8e-0pdxtq-f6@smtp-pxlsx.com</pre>
                        </td>
                    </tr>
                    <tr valign="top">
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">email_lbdetect</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">false</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">incoming</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">2021-03-02 15:49:06Z</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">info@phyalacting.com</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">&quot;Arts Conference&quot; &lt;info@phyalacting.com&gt;</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">mperego@watermelon.com</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">Conference: Call for Presentations</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;"></pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                    <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">https://www.youtube.com/user/artuniverseagency</pre>
                                    <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">https://www.facebook.com/iugte</pre>
                                    <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">http://www.performingartsconference.org</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">d10df5de-7b6e-11eb-92d2-f311b6178117</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">qpcm8d-13xmh1-dh@smtp-pxlsx.com</pre>
                        </td>
                    </tr>
                    <tr valign="top">
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">email_lbdetect</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">false</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">incoming</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">2021-03-02 15:49:07Z</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">info@phyalacting.com</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">&quot;Arts Conference&quot; &lt;info@phyalacting.com&gt;</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">mlparks@watermelon.com</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">Conference: Call for Presentations</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;"></pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                    <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">https://www.youtube.com/user/artuniverseagency</pre>
                                    <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">https://www.facebook.com/iugte</pre>
                                    <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">http://www.performingartsconference.org</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">d20a6f94-7b6e-11eb-9233-55e6ad1d6d11</pre>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #c3cbd4;">
                                <pre style="font-family: helvetica, arial, sans-serif; white-space: pre-wrap; margin: 0;">qpcm8g-08x7a5-nm@smtp-pxlsx.com</pre>
                        </td>
                    </tr>
            </tbody>
        </table>
    </div>
</div>

<div style="margin-top: 10px; border-top: 1px solid #c3cbd4;"></div>


<p style="margin: 20px; font-size: 11px; color: #999;">This is an automated email, however you can reply to this email or email SplunkIT (SplunkIT@watermelon.com) for Splunk questions and requests.  <br><br>Splunk &gt; Because ninjas are too busy</p>

    </body>
</html>
EOF

my $body_plain = << 'EOF';
The alert condition for '(FOO) emails that seem phishy (q=false)' was triggered.\nAlert Title:      (FOO) emails that seem phishy (q=false)\nAlert Location:   https://splunkit.watermelon.com/app/cyber/@go?dispatch_view=alert&s=%2FservicesNS%2Fnobody%2Fcyber%2Fsaved%2Fsearches%2F%2528FOO%2529%2520emails%2520that%2520seem%2520phishy%2520%2528q%253Dfalse%2529\nSearch String:    `email_lbdetect`  NOT x_feport_remotehost=\"phiest.nobe3.com\" summary=true [search sourcetype = MSExchange:2013:MessageTracking DELIVER [search `email_lbdetect` summary=true NOT quarantined=true newness newness:new_smtp_server:today newness:new_from:today \"url_count\"<4 (\"attachment_count\">0 OR \"url_count\">0) earliest=-1h | dedup message_id | rex field=message_id \"<?(?<MESSAGE_ID>[^>]*)\" |table message_id] earliest=-1h |fields message_id |rename message_id as search |format] | eval message_id=replace('message_id', \"\\<|\\>\",\"\") | table index quarantined msg_direction datetime x_feport_rcpt_from mail_from x_feport_rcpt_all subject attachment{}.file_name url{} rootUID message_id\n\n\n------------------------------------------------------------------------\nView results in Splunk: https://splunkit.watermelon.com/app/cyber/@go?sid=scheduler__foobar__cyber__RMD509a1f8c70cf0f0c0_at_1614701700_2182_A6F3AF33-1D3C-43C7-B086-A59444BA6A01\n\nquarantined        msg_direction        index                  x_feport_rcpt_all        datetime                    attachment{}.file_name        x_feport_rcpt_from                message_id                             rootUID                                     subject                                              url{}                                                 mail_from                                               \n-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\nfalse              incoming             email_lbdetect        rblehou@watermelon.com         2021-03-02 15:49:06Z                                      info@physalinacting.com        qpcm8d-0xfwa1-m2@smtp-pulse.com        d0f83078-7b6e-11eb-86f3-6155063c7f84        Conference: Call for Presentations                   https://www.youtube.com/user/artuniverseagency        \"Arts Conference\" <info@physalinacting.com>        \n                                                                                                                                                                                                                                                                                                                                https://www.facebook.com/iugte                                                                                \n                                                                                                                                                                                                                                                                                                                                http://www.performingartsconference.org                                                                       \n-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\nfalse              incoming             email_lbdetect        pbboche@watermelon.com         2021-03-02 15:49:06Z                                      info@physalinacting.com        qpcm8e-0pdxtq-f6@smtp-pulse.com        d164ce87-7b6e-11eb-be11-7b245233038c        Call for Presentations: IUGTE Conference 2021        https://www.youtube.com/user/artuniverseagency        \"Arts Conference\" <info@physalinacting.com>        \n                                                                                                                                                                                                                                                                                                                                https://www.facebook.com/iugte                                                                                \n                                                                                                                                                                                                                                                                                                                                http://www.performingartsconference.org                                                                       \n-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\nfalse              incoming             email_lbdetect        mperego@watermelon.com         2021-03-02 15:49:06Z                                      info@physalinacting.com        qpcm8d-13xmh1-dh@smtp-pulse.com        d10df5de-7b6e-11eb-92d2-f311b6178117        Conference: Call for Presentations                   https://www.youtube.com/user/artuniverseagency        \"Arts Conference\" <info@physalinacting.com>        \n                                                                                                                                                                                                                                                                                                                                https://www.facebook.com/iugte                                                                                \n                                                                                                                                                                                                                                                                                                                                http://www.performingartsconference.org                                                                       \n-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\nfalse              incoming             email_lbdetect        mlparks@watermelon.com         2021-03-02 15:49:07Z                                      info@physalinacting.com        qpcm8g-08x7a5-nm@smtp-pulse.com        d20a6f94-7b6e-11eb-9233-55e6ad1d6d11        Conference: Call for Presentations                   https://www.youtube.com/user/artuniverseagency        \"Arts Conference\" <info@physalinacting.com>        \n                                                                                                                                                                                                                                                                                                                                https://www.facebook.com/iugte                                                                                \n                                                                                                                                                                                                                                                                                                                                http://www.performingartsconference.org                                                                       \n-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n\n------------------------------------------------------------------------\n\nThis is an automated email, however you can reply to this email or email SplunkIT (SplunkIT@watermelon.com) for Splunk questions and requests.  \n\nSplunk > Because ninjas are too busy\n
EOF

my $message = {
    from    => 'splunk@splunk.watermelon.com',
    subject => 'Splunk alert: FOOBAR',
    message_id  => '<b02629f38b2d4bcba45a10b50d7db312@foobar.watermelon.com>',
    body_plain  => $body_plain,
    body_html   => $body_html,
};

ok($parser->will_parse($message), "Splunk Parser will parse");

my %result = $parser->parse_message($message);

is($result{subject}, $message->{subject}, "Correct Subject");
is($result{message_id}, $message->{message_id}, "Correct Message id");
is($result{body_plain}, $body_plain, "Body Plain unaltered");
is($result{body}, $body_html, "Body HTML unaltered");

cmp_deeply($result{source}, ["email", "splunk"], "Source is correct");
cmp_deeply($result{tag}, [], "Tag is correct");
cmp_deeply($result{columns}, ["index", "quarantined", "msg_direction", "datetime", "x_feport_rcpt_from", "mail_from", "x_feport_rcpt_all", "subject", "attachment{}-file_name", "url{}", "rootUID", "message_id"], "Columns are correct");
cmp_deeply($result{ahrefs}, [{
    "link" => 'https://splunkit.watermelon.com/app/cyber/@go?dispatch_view=alert&s=%2FservicesNS%2Fnobody%2Fcyber%2Fsaved%2Fsearches%2F%2528FOO%2529%2520emails%2520that%2520seem%2520phishy%2520%2528q%253Dfalse%2529',
    "subject" =>  "(FOO) emails that seem phishy (q=false)"
},
{
    "link" => 'https://splunkit.watermelon.com/app/cyber/@go?sid=scheduler__foobar__cyber__RMD509a1f8c70cf0f0c0_at_1614701700_2182_A6F3AF33-1D3C-43C7-B086-A59444BA6A01',
    "subject" =>  "View results in Splunk"
}
], "AHRefs are correct");

my $expected_data = [
    {
            'rootUID' => [
                           'd0f83178-7b1e-11e1-8613-6151063c1f84'
                         ],
            'quarantined' => [
                               'false'
                             ],
            'attachment{}-file_name' => [
                                          ''
                                        ],
            'datetime' => [
                            '2021-03-02 15:49:06Z'
                          ],
            'columns' => [
                           'index',
                           'quarantined',
                           'msg_direction',
                           'datetime',
                           'x_feport_rcpt_from',
                           'mail_from',
                           'x_feport_rcpt_all',
                           'subject',
                           'attachment{}-file_name',
                           'url{}',
                           'rootUID',
                           'message_id'
                         ],
            'subject' => [
                           'Conference: Call for Presentations'
                         ],
            'message_id' => [
                              'qpcm8d-0xfwax-m2@smtp-pxlsx.com'
                            ],
            'url{}' => [
                         'https://www.youtube.com/user/artuniverseagency',
                         ' ',
                         'https://www.facebook.com/iugte',
                         ' ',
                         'http://www.performingartsconference.org'
                       ],
            'msg_direction' => [
                                 'incoming'
                               ],
            'index' => [
                         'email_lbdetect'
                       ],
            'alert_name' => '(FOO) emails that seem phishy (q=false)',
            'x_feport_rcpt_from' => [
                                      'info@phyalinacting.com'
                                    ],
            'search' => ' `email_lbdetect` NOT x_feport_remotehost="phiest.nobe3.com" summary=true [search sourcetype = MSExchange:2013:MessageTracking DELIVER [search `email_lbdetect` summary=true NOT quarantined=true "url_count"<4 earliest=-1h | dedup message_id | rex field=message_id "<?(?<MESSAGE_ID>[^>]*)" |table message_id] earliest=-1h |fields message_id |rename message_id as search |format] | eval message_id=replace(\'message_id\', "\\\\<|\\\\>","") | table index quarantined msg_direction datetime x_feport_rcpt_from mail_from x_feport_rcpt_all subject attachment{}.file_name url{} message_id',
            'x_feport_rcpt_all' => [
                                     'rblxx@watermelon.com'
                                   ],
            'mail_from' => [
                             '"Arts Conference" <info@phyalinacting.com>'
                           ]
          },
          {
            'index' => [
                         'email_lbdetect'
                       ],
            'msg_direction' => [
                                 'incoming'
                               ],
            'search' => ' `email_lbdetect` NOT x_feport_remotehost="phiest.nobe3.com" summary=true [search sourcetype = MSExchange:2013:MessageTracking DELIVER [search `email_lbdetect` summary=true NOT quarantined=true "url_count"<4 earliest=-1h | dedup message_id | rex field=message_id "<?(?<MESSAGE_ID>[^>]*)" |table message_id] earliest=-1h |fields message_id |rename message_id as search |format] | eval message_id=replace(\'message_id\', "\\\\<|\\\\>","") | table index quarantined msg_direction datetime x_feport_rcpt_from mail_from x_feport_rcpt_all subject attachment{}.file_name url{} message_id',
            'x_feport_rcpt_all' => [
                                     'pbboche@watermelon.com'
                                   ],
            'mail_from' => [
                             '"Arts Conference" <info@phyalacting.com>'
                           ],
            'x_feport_rcpt_from' => [
                                      'info@phyalinacting.com'
                                    ],
            'alert_name' => '(FOO) emails that seem phishy (q=false)',
            'columns' => [
                           'index',
                           'quarantined',
                           'msg_direction',
                           'datetime',
                           'x_feport_rcpt_from',
                           'mail_from',
                           'x_feport_rcpt_all',
                           'subject',
                           'attachment{}-file_name',
                           'url{}',
                           'rootUID',
                           'message_id'
                        ],
            'subject' => [
                           'Call for Presentations: IUGTE Conference 2021'
                         ],
            'message_id' => [
                              'qpcm8e-0pdxtq-f6@smtp-pxlsx.com'
                            ],
            'url{}' => [
                         'https://www.youtube.com/user/artuniverseagency',
                         ' ',
                         'https://www.facebook.com/iugte',
                         ' ',
                         'http://www.performingartsconference.org'
                       ],
            'datetime' => [
                            '2021-03-02 15:49:06Z'
                          ],
            'quarantined' => [
                               'false'
                             ],
            'attachment{}-file_name' => [
                                          ''
                                        ],
            'rootUID' => [
                           'd164ce87-7b6e-11eb-be11-7b245233038c'
                         ]
          },
          {
            'datetime' => [
                            '2021-03-02 15:49:06Z'
                          ],
            'attachment{}-file_name' => [
                                          ''
                                        ],
            'quarantined' => [
                               'false'
                             ],
            'rootUID' => [
                           'd10df5de-7b6e-11eb-92d2-f311b6178117'
                         ],
            'x_feport_rcpt_all' => [
                                     'mperego@watermelon.com'
                                   ],
            'search' => ' `email_lbdetect` NOT x_feport_remotehost="phiest.nobe3.com" summary=true [search sourcetype = MSExchange:2013:MessageTracking DELIVER [search `email_lbdetect` summary=true NOT quarantined=true "url_count"<4 earliest=-1h | dedup message_id | rex field=message_id "<?(?<MESSAGE_ID>[^>]*)" |table message_id] earliest=-1h |fields message_id |rename message_id as search |format] | eval message_id=replace(\'message_id\', "\\\\<|\\\\>","") | table index quarantined msg_direction datetime x_feport_rcpt_from mail_from x_feport_rcpt_all subject attachment{}.file_name url{} message_id',
            'mail_from' => [
                             '"Arts Conference" <info@phyalacting.com>'
                           ],
            'x_feport_rcpt_from' => [
                                      'info@phyalacting.com'
                                    ],
            'alert_name' => '(FOO) emails that seem phishy (q=false)',
            'msg_direction' => [
                                 'incoming'
                               ],
            'index' => [
                         'email_lbdetect'
                       ],
            'url{}' => [
                         'https://www.youtube.com/user/artuniverseagency',
                         ' ',
                         'https://www.facebook.com/iugte',
                         ' ',
                         'http://www.performingartsconference.org'
                       ],
            'message_id' => [
                              'qpcm8d-13xmh1-dh@smtp-pxlsx.com'
                            ],
            'columns' => [
                           'index',
                           'quarantined',
                           'msg_direction',
                           'datetime',
                           'x_feport_rcpt_from',
                           'mail_from',
                           'x_feport_rcpt_all',
                           'subject',
                           'attachment{}-file_name',
                           'url{}',
                           'rootUID',
                           'message_id'
                        ],
            'subject' => [
                           'Conference: Call for Presentations'
                         ]
          },
          {
            'msg_direction' => [
                                 'incoming'
                               ],
            'index' => [
                         'email_lbdetect'
                       ],
            'alert_name' => '(FOO) emails that seem phishy (q=false)',
            'x_feport_rcpt_all' => [
                                     'mlparks@watermelon.com'
                                   ],
            'search' => ' `email_lbdetect` NOT x_feport_remotehost="phiest.nobe3.com" summary=true [search sourcetype = MSExchange:2013:MessageTracking DELIVER [search `email_lbdetect` summary=true NOT quarantined=true "url_count"<4 earliest=-1h | dedup message_id | rex field=message_id "<?(?<MESSAGE_ID>[^>]*)" |table message_id] earliest=-1h |fields message_id |rename message_id as search |format] | eval message_id=replace(\'message_id\', "\\\\<|\\\\>","") | table index quarantined msg_direction datetime x_feport_rcpt_from mail_from x_feport_rcpt_all subject attachment{}.file_name url{} message_id',
            'x_feport_rcpt_from' => [
                                      'info@phyalacting.com'
                                    ],
            'mail_from' => [
                             '"Arts Conference" <info@phyalacting.com>'
                           ],
            'message_id' => [
                              'qpcm8g-08x7a5-nm@smtp-pxlsx.com'
                            ],
            'columns' => [
                           'index',
                           'quarantined',
                           'msg_direction',
                           'datetime',
                           'x_feport_rcpt_from',
                           'mail_from',
                           'x_feport_rcpt_all',
                           'subject',
                           'attachment{}-file_name',
                           'url{}',
                           'rootUID',
                           'message_id'
                        ],
            'subject' => [
                           'Conference: Call for Presentations'
                         ],
            'url{}' => [
                         'https://www.youtube.com/user/artuniverseagency',
                         ' ',
                         'https://www.facebook.com/iugte',
                         ' ',
                         'http://www.performingartsconference.org'
                       ],
            'datetime' => [
                            '2021-03-02 15:49:07Z'
                          ],
            'rootUID' => [
                           'd20a6f94-7b6e-11eb-9233-55e6ad1d6d11'
                         ],
            'quarantined' => [
                               'false'
                             ],
            'attachment{}-file_name' => [
                                          ''
                                        ]
          }
        ];

cmp_deeply($result{data}, $expected_data, "Data is correct");
done_testing();
