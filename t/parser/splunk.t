#!/usr/bin/env perl
use HTML::TreeBuilder;
use Data::Dumper;


my $html = qq|<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\"><html xmlns=\"http://www.w3.org/1999/xhtml\"><head>\r\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\n    </head>\n    <body style=\"font-size: 14px; font-family: helvetica, arial, sans-serif; padding: 20px 0; margin: 0; color: #333;\">\n        <div style=\"margin: 0 20px;\">The scheduled report '(FOO) watermelon.com subdomain in the email HREF' has run.</div>\n<table cellpadding=\"0\" cellspacing=\"0\" border=\"0\" class=\"summary\" style=\"margin: 20px;\">\n    <tbody>\n        <tr>\n            <th style=\"font-weight: normal; text-align: left; padding: 0 20px 10px 0;\">Report:</th><td style=\"padding: 0 0 10px 0;\"><a href=\"https://mx34qerqe.watermelon.com:8000/app/search/report?s=%2FservicesNS%2Fenhan%2Fsearch%2Fsaved%2Fsearches%2F%2528FOO%2529%2520watermelon.com%2520subdomain%2520in%2520the%2520email%2520HREF&amp;sid=scheduler__enhan__search__RMD5f9c486656dafc73c_at_1431810000_54403\" style=\" text-decoration: none; margin: 0 40px 0 0; color: #5379AF;\">(FOO) watermelon.com subdomain in the email HREF</a></td>\n        </tr>\n    </tbody>\n</table>\n\n\n<div style=\"margin-top: 10px; border-top: 1px solid #ccc;\"></div>\n\n\n<p style=\"margin: 20px; font-size: 11px; color: #999;\">If you believe you've received this email in error, please see your Splunk administrator.<br><br>splunk &gt; the engine for machine data</p>\n\n    </body>\n</html>\n|;


my $tree    = HTML::TreeBuilder->new;
$tree       ->implicit_tags(1);
$tree       ->implicit_body_p_tag(1);
$tree       ->parse_content($html);

unless ( $tree ) {
    $log->error("Unable to Parse HTML!");
    $log->error("Body = $body");
    return undef;
}

my @tables = $tree->look_down('_tag','table');

#print ref(@tables);
print scalar(@tables)." tables in html\n";

print Dumper(@tables);
