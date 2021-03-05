package Scot::Email::Parser::Splunk;

use lib '../../../../lib';
use HTML::TreeBuilder;
use Data::Dumper;
use Moose;
extends 'Scot::Email::Parser';

sub get_sourcename {
    return "splunk";
}

sub will_parse {
    my $self    = shift;
    my $href    = shift;
    my $from    = $href->{from};
    my $subject = $href->{subject};
    my $splunk_email    = $self->env->splunk_sender;

    if ( $subject =~ /splunk alert/i ) {
        return 1;
    }
    if ( $from =~ /$splunk_email/ ) {
        return 1;
    }
    return undef;
}

sub parse_message {
    my $self    = shift;
    my $message = shift;
    my $log     = $self->env->log;

    $log->debug("Parsing SPLUNK email");

    my $body    = $self->normalize_body($message);
    my $tree    = $self->build_html_tree($body);

    if ( ! defined $tree ) {
        $log->error("Unable to parse message body!",
                    { filter => \&Dumper, value => $message });
        return undef;
    }

    my @splunk_links = $self->extract_splunk_links($tree);
    my ($alertname, $search, $tag_aref ) = $self->extract_splunk_info($tree);
    my ($columns, $alerts) = $self->extract_splunk_results($tree, $alertname, $search);

    my %json    = (
        subject     => $message->{subject},
        message_id  => $message->{message_id},
        body_plain  => $message->{body_plain},
        body        => $message->{body_html},
        data        => [],
        source      => [ 'email', 'splunk' ],
        tag         => $tag_aref,
        columns     => $columns,
        data        => $alerts,
        ahrefs      => \@splunk_links,
    );

    return wantarray ? %json : \%json;
}

sub normalize_body {
    my $self    = shift;
    my $message = shift;
    my $log     = $self->env->log;
    my $body    = $message->{body_html};

    if ( ! defined $body ) {
        $body   = $message->{body};
    }
    if ( ! defined $body ) {
        $body   = $message->{body_plain};
    }

    unless ( $body =~ /\<html.*\>/ or $body =~ /DOCTYPE html/ ) {
        my $warning = qq{Splunk Message was not in HTML format!  Parsing will be incomplete.  Please set Splunk alert to HTML output via Splunk."};
        $log->warn($warning);
        $body = qq{<html><body><div class="warn">$warning</div><div class="orig_body">$body</div></body></html>};
    }
    return $body;
}

sub build_html_tree {
    my $self    = shift;
    my $body    = shift;
    my $log     = $self->env->log;
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

sub extract_splunk_links {
    my $self    = shift;
    my $tree    = shift;
    my @links   = ();

    my @anchors = $tree->look_down('_tag', 'a');

    foreach my $anchor (@anchors) {
        my @content = $anchor->content_list;
        my $text    = join(' ', @content);
        my $href    = $anchor->attr('href');
        push @links, {
            subject => $text,
            link    => $href,
        };
    }
    return wantarray ? @links : \@links;
}

sub extract_splunk_info {
    my $self    = shift;
    my $tree    = shift;
    my $top_table   = ($tree->look_down('_tag', 'table'))[0];
    my $alertname   = "splunk parse error";
    my $search      = "See Source Email for Search";
    my @tags        = ();

    if ( $top_table ) {
        my @top_table_tds   = $top_table->look_down('_tag', 'td');
        $search = "Splunk is not sending Search Terms!";
        if ( scalar(@top_table_tds) > 1 ) {
            $search = $top_table_tds[1]->as_text;
            @tags   = $self->extract_splunk_tags($search);
        }
        $alertname = "Unknown Alert Name";
        if ( defined $top_table_tds[0] ) {
            $alertname = $top_table_tds[0]->as_text;
        }
    }
    return $alertname, $search, \@tags;
}

sub extract_splunk_tags {
    my $self    = shift;
    my $search  = shift;
    my @tags    = ();

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

sub extract_splunk_results {
    my $self        = shift;
    my $tree        = shift;
    my $alertname   = shift;
    my $search      = shift;
    my $log         = $self->env->log;

    my $report  = $self->extract_report($tree);
    if ( ! defined $report ) {
        $log->error("Report Table NOT FOUND!");
        return undef, undef;
    }

    my ($rows, $columns) = $self->extract_rows_columns($report);
    my $results          = $self->extract_results($rows, $columns);


    # add the following to each alert
    map { 
        $_->{alert_name} = $alertname; 
        $_->{search} = $search;
        $_->{columns} = $columns;
    } @$results;

    return $columns, $results;
}

sub extract_report {
    my $self    = shift;
    my $tree    = shift;
    my $report  = ($tree->look_down('_tag','table'))[1];
    return $report;
}

sub extract_rows_columns {
    my $self    = shift;
    my $report  = shift;
    my @rows    = $report->look_down('_tag','tr');
    my $header  = shift @rows;
    my @columns = $self->extract_columns($header);
    return \@rows, \@columns;
}

sub extract_results {
    my $self    = shift;
    my $rows    = shift;
    my $columns = shift;
    my @results = ();
    my $empty_col_index = 1;

    foreach my $row (@$rows) {
        my @values  = $row->look_down('_tag','td');
        my $result  = {};
        for (my $i = 0; $i < scalar(@values); $i++ ) {
            my $name    = $columns->[$i];
            if ( ! $name ) {
                $name = "c".$empty_col_index++;
            }
            my $cell    = $values[$i];
            my @children    = map {
                ref($_) eq "HTML::Element" ? $_->as_text : $_
            } $cell->content_list;
            $result->{$name} = \@children;
        }
        push @results, $result;
    }
    return \@results;
}

sub extract_columns {
    my $self    = shift;
    my $header  = shift;

    my @columns = map { $_->as_text; } $header->look_down('_tag','th');
    if (scalar(@columns) == 0) {
        # thanks Outlook for changing th to td when viewing email
        @columns = map { $_->as_text; } $header->look_down('_tag','td');
    }
    s/\./-/g for @columns;  # strip '.' because it breaks mongo
    return wantarray ? @columns : \@columns;
}


1;    
