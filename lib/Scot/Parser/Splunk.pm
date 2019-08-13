package Scot::Parser::Splunk;

use lib '../../../lib';
use HTML::TreeBuilder;
use Data::Dumper;
use Moose;

extends 'Scot::Parser';

sub will_parse {
    my $self    = shift;
    my $href    = shift;
    my $from    = $href->{from};
    my $subject = $href->{subject};

    if ( $subject =~ /splunk alert/i ) {
        return 1;
    }
    # TODO remove email address to config
    if ( $from =~ /splunk\@sandia.gov/i ) {
        return 1;
    }
    return undef;
}

sub parse_message {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->log;

    my %json    = (
        subject     => $href->{subject},
        message_id  => $href->{message_id},
        body_plain  => $href->{body_plain},
        body        => $href->{body_html},
        data        => [],
        source      => [ qw(email splunk) ],
    );

    $log->debug("Parsing SPLUNK email", {filter=>\&Dumper, value=>$href});

    my $body    = $href->{body_html} // $href->{body};
    $body = $href->{body_plain} unless defined $body;

    $log->debug("body is $body");

    unless ($body =~ /\<html.*\>/i or $body =~ /DOCTYPE html/) {
        # someone forgot to tell splunk to send html email!
        # parsing of plain email not supported, but this 
        # keeps it from blowing up.
        $log->warn("Splunk message was not in HTML.");
        $log->warn("wrapping in html, but parsing will not work!");
        my $warning = qq{
            <body>
            <h3>Splunk E-mail was not in HTML Format.  Parsing incomplete.  Please set Splunk alert to HTML output in Splunk.</h3><br>
        };
        $body   = "<html>".$warning.$body."</body></html>"; 
    }
    else {
        $log->debug("detected html");
    }

    my $tree    = $self->build_html_tree($body);

    unless ( $tree ) {
        return undef;
    }

    my @ahrefs = $tree->look_down('_tag',"a");
    # @ahrefs = map { $_->as_HTML; } @ahrefs;
    my @splunklinks = ();

    foreach my $anchor (@ahrefs) {
        my @content = $anchor->content_list;
        my $text    = join(' ',@content);
        my $href    = $anchor->attr('href');
        push @splunklinks, {
            subject => $text,
            link    => $href,
        };
    }

    my ($alertname, $search, $tagaref) = $self->get_splunk_report_info($tree);

    my $report  = ( $tree->look_down('_tag','table') )[1];
    unless ($report) {
        $log->warn("No tables in Splunk Email!");
        return wantarray ? %json : \%json;
    }

    my @rows    = $report->look_down('_tag','tr');
    my $header  = shift @rows;
    my @columns = map { $_->as_text; } $header->look_down('_tag','th');

    if ( scalar(@columns) == 0 ) {
        # microsoft email clients will actually rewrite the html!
        # so if a user forwards something into SCOT, TH's become TD's
        @columns    = map { $_->as_text; } $header->look_down('_tag','td');
    }
    # strip periods from column names, because this breaks mongo
    s/\./-/g for @columns;

    my @results             = ();
    my @msg_id_entities     = ();
    my $empty_col_replace   = 1;

    foreach my $row (@rows) {
        my @values      = $row->look_down('_tag','td');
        my %rowresult   = (
            alert_name  => $alertname,
            search      => $search,
            columns     => \@columns,
        );
        for ( my $i = 0; $i < scalar(@values); $i++ ) {
            my $colname = $columns[$i];
            unless ($colname) {
                $colname    = "c". $empty_col_replace++;
                $log->warn("Empty Column Name detected");
                $log->warn("replacing column name with $colname");
            }

            my $cell = $values[$i];
            # $rowresult{$colname} = $cell;
            my @children   = map {
              if ( ref($_) eq "HTML::Element" ) {
                $_->as_text;
              } 
              else {
                $_;
              }
            } $cell->content_list;
            $rowresult{$colname} = \@children
        }
        push @results, \%rowresult;
    }
    $json{data}     = \@results;
    $json{columns}  = \@columns;
    $json{tag}      = $tagaref;
    # $json{ahrefs}   = \@ahrefs;
    $json{ahrefs}   = \@splunklinks;

    if ( length($json{body}) > 1000000 ) {
        $json{body}         = qq|Email Body too large.  View in Email client.|;
        $json{body_plain}   = qq|Email Body too large.  View in Email client.|;
    }

    return wantarray ? %json : \%json;
}

sub get_splunk_report_info {
    my $self          = shift;
    my $tree          = shift;
    my $top_table     = ( $tree->look_down('_tag', 'table') )[0];
    unless ( $top_table ) {
        return "splunk parse error", "see source for search";
    }
    my @top_table_tds = $top_table->look_down('_tag', 'td');

    my $search        = "splunk is not sending the search terms";
    if ( scalar(@top_table_tds) > 1 ) {
        $search       = $top_table_tds[1]->as_text;
    }
    my $alertname     = "unknown alert name";
    if ( defined $top_table_tds[0] ) {
        $alertname = $top_table_tds[0]->as_text;
    }

    my @tags    = $self->extract_splunk_tags($search);

    return $alertname, $search, \@tags;
}

sub extract_splunk_tags {
    my $self    = shift;
    my $search  = shift;
    my @tags    = ();
    my $log     = $self->log;
    # XXX put regexes to pull them out here

    my $regex = qr{
        (sourcetype=.*?)\ |
        (index=.*?)\ |
        (tag=.*?)\ |
        (source=.*?)\  
    }xms;

    foreach my $m ($search =~ m/$regex/g) {
        next if ( ! defined $m );
        next if ( $m eq '' );
        push @tags, $m;
    }

    return wantarray ? @tags : \@tags;
}

sub build_html_tree {
    my $self    = shift;
    my $body    = shift;
    my $log     = $self->log;
    my $tree    = HTML::TreeBuilder->new;
    $tree       ->implicit_tags(1);
    $tree       ->implicit_body_p_tag(1);
    $tree       ->parse_content($body);

    unless ( $tree ) {
        $log->error("Unable to Parse HTML!");
        $log->error("Body = $body");
        return undef;
    }
    return $tree;
}
sub get_sourcename {
    return "splunk";
}
1;




