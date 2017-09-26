#!/usr/bin/env perl
use v5.18;
use HTML::TreeBuilder;
use Data::Dumper;


my $html = q{
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html xmlns="http://www.w3.org/1999/xhtml"><head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    </head>
    <body style="font-size: 14px; font-family: helvetica, arial, sans-serif; padding: 20px 0; margin: 0; color: #333;">
        <div style="margin: 0 20px;">The alert condition for '(JCJ) Synapse user agent web scans' was triggered.</div>
<table cellpadding="0" cellspacing="0" border="0" class="summary" style="margin: 20px;">
    <tbody>
        <tr>
            <th style="font-weight: normal; text-align: left; padding: 0 20px 10px 0;">Alert:</th><td style="padding: 0 0 10px 0;"><a href="https://ms27snllx.sandia.gov:8000/app/search/alert?s=%2FservicesNS%2Fnobody%2Fsearch%2Fsaved%2Fsearches%2F%2528JCJ%2529%2520Synapse%2520user%2520agent%2520web%2520scans" style=" text-decoration: none; margin: 0 40px 0 0; color: #5379AF;">(JCJ) Synapse user agent web scans</a></td>
        </tr>
        <tr>
            <th style="font-weight: normal; text-align: left; padding: 0 20px 10px 0;">Search String:</th><td style="padding: 0 0 10px 0;">tag=browww user_agent=&quot;Mozilla/4.0 (compatible; Synapse)&quot; NOT (status_code=404 OR status_code=301 OR referer=&quot;http://www.commoninsider.com&quot;) | localop | lookup geoasn src_ip as src | eval url=hostname &#43; uri | cluster field=uri showcount=t labelonly=true match=ngramset  | transaction cluster_label mvlist=t nullstr=&quot;-&quot; | transaction src mvlist=t nullstr=&quot;-&quot; | table _time cluster_count cluster_label proxied src src_asn status_code http_method hostname uri referer bytes cookie</td>
        </tr>
    </tbody>
</table>


<div style="margin-top: 10px; padding-top: 20px; border-top: 1px solid #ccc;"></div>
<div style="margin: 0 20px;">
    <a href="https://ms27snllx.sandia.gov:8000/app/search/@go?sid=scheduler__jcjaroc__search__RMD53e90eb4f8fad6194_at_1496584800_10658" style=" text-decoration: none; color: #5379AF;">View results in Splunk</a>
</div>

<div style="margin:0">
    <div style="overflow: auto; width: 100%;">
        <table cellpadding="0" cellspacing="0" border="0" class="results" style="margin: 20px;">
            <tbody>
                
                <tr>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">_time</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">cluster_count</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">cluster_label</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">proxied</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">src</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">src_asn</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">status_code</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">http_method</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">hostname</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">uri</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">referer</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">bytes</th>
                        
                        <th style="text-align: left; padding: 4px 8px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">cookie</th>
                </tr>
                    <tr valign="top">
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">
                                <div style="white-space: pre-wrap;">Sat Jun  3 08:23:17 2017</div>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">
                                    <div style="white-space: pre-wrap;">2</div>
                                    <div style="white-space: pre-wrap;">2</div>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">
                                    <div style="white-space: pre-wrap;">1</div>
                                    <div style="white-space: pre-wrap;">1</div>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">
                                    <div style="white-space: pre-wrap;">-</div>
                                    <div style="white-space: pre-wrap;">-</div>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">
                                    <div style="white-space: pre-wrap;">178.137.92.125</div>
                                    <div style="white-space: pre-wrap;">178.137.92.125</div>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">
                                    <div style="white-space: pre-wrap;">AS15895 &quot;Kyivstar&quot; PJSC</div>
                                    <div style="white-space: pre-wrap;">AS15895 &quot;Kyivstar&quot; PJSC</div>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">
                                    <div style="white-space: pre-wrap;">403</div>
                                    <div style="white-space: pre-wrap;">403</div>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">
                                    <div style="white-space: pre-wrap;">GET</div>
                                    <div style="white-space: pre-wrap;">GET</div>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">
                                    <div style="white-space: pre-wrap;">imr.sandia.gov</div>
                                    <div style="white-space: pre-wrap;">crf.sandia.gov</div>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">
                                    <div style="white-space: pre-wrap;">/wp-login.php</div>
                                    <div style="white-space: pre-wrap;">/wp-login.php</div>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">
                                    <div style="white-space: pre-wrap;">-</div>
                                    <div style="white-space: pre-wrap;">-</div>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">
                                    <div style="white-space: pre-wrap;">278</div>
                                    <div style="white-space: pre-wrap;">278</div>
                        </td>
                        <td style="text-align: left; padding: 4px 8px; margin-top: 0px; margin-bottom: 0px; border-bottom: 1px dotted #ccc;">
                                    <div style="white-space: pre-wrap;">-</div>
                                    <div style="white-space: pre-wrap;">-</div>
                        </td>
                    </tr>
            </tbody>
        </table>
    </div>
</div>

<div style="margin-top: 10px; border-top: 1px solid #ccc;"></div>


<p style="margin: 20px; font-size: 11px; color: #999;">If you believe you've received this email in error, please see your Splunk administrator.<br><br>splunk &gt; the engine for machine data</p>

    </body>
</html>
};


my $tree    = HTML::TreeBuilder->new;
$tree       ->implicit_tags(1);
$tree       ->implicit_body_p_tag(1);
$tree       ->parse_content($html);

unless ( $tree ) {
    say "Unable to Parse HTML!";
    say "Body = $html";
    return undef;
}

my $report  = ( $tree->look_down('_tag', 'table') )[1];
my @rows    = $report->look_down('_tag', 'tr');
my $header  = shift @rows;
my @columns = map { $_->as_text; } $header->look_down('_tag','th');

foreach my $row (@rows) {
    my @values  = $row->look_down('_tag','td');

    foreach my $value (@values) {
        say "------ TD ----------";
        my $element_count = scalar(@{$value->{_content}});
        say " element_count = $element_count";
        say $value->as_text;
        say "====";
        foreach my $v (@{$value->{_content}}) {
            say $v->as_text;
        }
    }
}
