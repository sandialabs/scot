package Scot::Email::Parser::Splunk;

use lib '../../../lib';
use strict;
use warnings;

use Data::Dumper;
use String::Clean::XSS;
use Moose;
extends 'Scot::Email::Parser';

sub parse {
    my $self    = shift;
    my $msg     = shift;
    my $log     = $self->env->log;

    $log->debug(ref($self)." parsing begins");

    my ($courriel, $html, $plain ) = $self->get_body($msg->{message_str});

    if ( $self->body_not_html($html) ) {
        $html = $self->wrap_non_html($html,$plain);
        $log->trace("Wrapped non html email like this: ".$html);
    }

    my $tree    = $self->build_html_tree($html);

    my @anchors      = $tree->look_down('_tag','a');
    my @splunklinks  = $self->get_splunk_links(@anchors);
    my ($alertname,
        $search,
        $tags)       = $self->get_splunk_report_info($tree);

    my ($alerts, $columns)   = $self->get_alert_results($tree, $alertname, $search);


    my %json    = (
        subject => $msg->{subject},
        data    => $alerts,
        columns => $columns,
        source  => [qw(email splunk)],
        tag     => $tags,
        ahrefs  => \@splunklinks,
        body    => $html,
        body_plain  => $plain,
        message_id  => $msg->{message_id},
    );

    if ( $self->document_too_large(\%json) ) {
        $log->warn("Alertgroup Document too large! Trimming body");
        $json{body}       = qq|Email body too large, view in email client.|;
        $json{body_plain} = qq|Email body too large, view in email client.|;
        if ( $self->document_too_large(\%json) ) {
            $log->error("Trimming document did not reduce sufficiently");
        }
    }

    # $log->debug("json is ",{filter=>\&Dumper, value=>\%json});
    return wantarray ? %json : \%json;
}

sub document_too_large {
    my $self    = shift;
    my $doc     = shift;
    my $size    = 
        length($doc->{subject}) + 
        length($doc->{body}) + 
        length($doc->{body_plain}) +
        length($doc->{message_id});

    $self->env->log->debug("approx size is $size");

    return ($size > 1000000);
}

sub get_splunk_report_info {
    my $self    = shift;
    my $tree    = shift;
    my $toptbl  = ($tree->look_down('_tag', 'table'))[0];

    if ( ! $toptbl ) {
        return "splunk parse error", "See Source for Search", ['parse_error'];
    }

    my @toptbl_tds  = $toptbl->look_down('_tag', 'td');

    my $search = scalar(@toptbl_tds) > 1 ? $toptbl_tds[1]->as_text :
                                           "splunk not sending search terms";

    my $alertname = defined $toptbl_tds[0] ? $toptbl_tds[0]->as_text : 
                                             "unknown alert name";

    my @tags = $self->extract_splunk_tags($search);

    return $alertname, $search, \@tags;
}

sub extract_splunk_tags {
    my $self    = shift;
    my $search  = shift;
    my @tags    = ();
    my $log     = $self->env->log;

    my $regex   = qr{
        (sourcetype=.*?)\ |
        (index=.*?)\ |
        (tag=.*?)\ |
        (source=.*?)\
    }xms;

    foreach my $match ($search =~ m/$regex/g) {
        next if (! defined $match);
        next if ( $match eq '');
        push @tags, $match;
    }

    return wantarray ? @tags : \@tags;
}


sub get_alert_results {
    my $self    = shift;
    my $tree    = shift;
    my $alertname = shift;
    my $search  = shift;
    my $log     = $self->env->log;

    # alert results are in second table of html document
    my $table   = ($tree->look_down('_tag','table'))[1];

    if ( ! defined $table ) {
        $log->error("No Alert Results");
        return [], [];
    }

    my @rows    = $table->look_down('_tag','tr');
    my $header  = shift @rows;
    my @columns = $self->get_columns($header);
    my @results = $self->parse_rows(\@columns, \@rows);


    # add these to each row
    map { 
        $_->{alert_name} = $alertname;
        $_->{search}     = $search;
        $_->{columns}    = \@columns;
    } @results;

    return \@results, \@columns;

}

sub get_columns {
    my $self    = shift;
    my $header  = shift;

    my @columns = map { $_->as_text; } $header->look_down('_tag','th');

    if ( scalar(@columns) == 0 ) {
        # outlook often re-writes the th's to td's.  Why MS?
        @columns = map { $_->as_text; } $header->look_down('_tag','td');
    }

    # strip '.' from names because it breaks mongo
    s/\./-/g for @columns;

    $self->env->log->debug("Got Columns: ".join(', ',@columns));

    return wantarray ? @columns : \@columns;
}

    



sub parse_rows {
    my $self    = shift;
    my $cols    = shift;
    my $rows    = shift;
    my $empty_replace = 1;
    my @results = ();

    foreach my $row (@$rows) {
        my %rowresult;
        my @values  = $row->look_down('_tag','td');
        for ( my $i = 0; $i < scalar(@values); $i++ ) {
            my $col_name = $cols->[$i];
            if ( ! $col_name ) {
                $col_name = "c".$empty_replace++;
            }
            my $cell    = $values[$i];
            my @children = map {
                ref($_) eq "HTML::Element" ? convert_XSS($_->as_text) : $_
            } $cell->content_list;
            $rowresult{$col_name} = \@children;
        }
        push @results, \%rowresult;
    }
    return wantarray ? @results : \@results;
}

sub get_splunk_links {
    my $self    = shift;
    my @anchors = @_;
    my @links   = ();

    foreach my $a (@anchors) {
        my @content = $a->content_list;
        my $text    = join(' ',@content);
        my $href    = $a->attr('href');
        push @links, {
            subject => $text,
            link    => $href,
        };
    }
    return wantarray ? @links : \@links;
}

sub wrap_non_html {
    my $self    = shift;
    my $html    = shift;
    my $plain   = shift;
    my $new     = qq{
        <html>
         <body>
          <h3>Splunk Email was not in HTML format. Parsing Incomplete.</h3>
          <h4>To Fix: set splunk alert to HTML output in Splunk</h4>
          <pre>
            $plain
          </pre>
         </body>
        </html>
    };
    return $new;
}


1;
