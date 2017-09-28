#!/usr/bin/env perl 

my $source = '(sourcetype=hybrid_email hoursago=24) OR (index=lb hoursago=24 summary=true) OR (tag=exchange spam@sandia.gov) NOT ("FW: [Plug] Your daily details" OR "mpl.ack@axway.com") |eval sub=coalesce(message_subject,subject) | eval recipient=coalesce(recipient,mail-to) | eval sender=coalesce(sender,mail-from) | spath output=lb_links "urls{}" | spath output=lb_files "attachments{}" | eval file_names=coalesce(lb_files, filenames) | eval html_links=coalesce(html_links,lb_links) | rex mode=sed field=sub "s/^.*\[EXTERNAL\] //" | eventstats sum(eval(if(recipient="spam@sandia.gov",1,0))) as times_reported, count(docid) as count_hy, count(scanid) as count_lb, values(recipient) as rec, values(sender) as senders, earliest(html_links) as html_links, earliest(file_names) as file_names, earliest(docid) as first_docid, earliest(scanid) as lbscanid, earliest(MESSAGE_ID) as message_id by sub | sort by -times_reported, sub | eval count=coalesce(count_hy, count_lb) | where count>0 AND times_reported>0 | dedup sub | eval rec=mvfilter(match(rec,"sandia.gov") AND NOT match(rec,"spam@sandia.gov")) | rename sub as message_subject, rec as recipients | table _time message_subject count senders recipients first_docid lbscanid html_links file_names message_id';

my $regex   = qr{
    (sourcetype=.*?)\ |
    (index=.*?)\ | 
    (tag=.*?)\ 
}xms;

my @matches = ($source =~ m/$regex/g);

foreach my $m (@matches) {
    next if ( $m eq '');
    print $m."\n";
}
