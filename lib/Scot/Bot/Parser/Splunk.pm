package Scot::Bot::Parser::Splunk;

use lib '../../../../lib';
use strict;
use warnings;
use v5.10;

use Mail::IMAPClient;
use Mail::IMAPClient::BodyStructure;
use MIME::Base64;
use HTML::TreeBuilder;
use MongoDB;
use Scot::Model::Alert;
use Scot::Util::Mongo;
use HTML::Entities;
use Data::Dumper;

use Moose;
extends 'Scot::Bot::Parser';


sub parse_body {
    my $self    = shift;
    my $bhref   = shift;
    my $body    = $bhref->{html};
    my $log     = $self->env->log;

    $log->debug("Parsing Splunk Message Body");

    my  $tree   = HTML::TreeBuilder->new;
        $tree   ->implicit_tags(1);
        $tree   ->implicit_body_p_tag(1);
        $tree   ->parse_content($body);

    # splunk 6 now puts the search name in a table!
    # and omits search terms

    my $text        = $tree->as_text( skip_dels => 1 );
    $text           =~ m/ Name: '(.*?)'[ ]+Query/;
    # my $alertname   = $1;
    #$text           =~ m/Query Terms: '(.*?)'[ ]+Link/;
    #(my $search = $1 )     =~ s/\\"/"/g; 
    #$search      = encode_entities($search);

    my $top_table = ( $tree->look_down('_tag', 'table') )[0];
    my @top_table_tds = $top_table->look_down('_tag', 'td');
    my $alertname   = $top_table_tds[0]->as_text;
    my $search      = "splunk is not sending the search terms";
    if ( scalar(@top_table_tds) > 1 ) {
        $search      = $top_table_tds[1]->as_text;
    }

    my $table   = ( $tree->look_down('_tag', 'table') )[1];

    unless ($table) {
        $log->error("No Tables in Splunk Email!");
        return [],[];
    }

    my @rows    = $table->look_down('_tag', 'tr');
    my $header  = shift @rows;
    my @columns = map { $_->as_text; } $header->look_down('_tag', 'th');

    if (scalar(@columns) == 0) {
        # it seems that micro$oft outlook clients will rewrite valid
        # splunk HTML into Fugly broken HTML when forwarding.
        # this case deals with a splunk email sent to a user who then
        # forwards it to scot using a outlook client.
        @columns = map { $_->as_text; } $header->look_down('_tag', 'td');
    }

    my @results = ();
    my @msg_id_entities;

    my $empty_col_replace   = 1;

    foreach my $row (@rows) {
        my @values  = $row->look_down('_tag','td');
        my %rowres  = (
            alert_name  => $alertname,
            search      => $search,
            columns     => \@columns,
        );
        for ( my $i = 0; $i < scalar(@values); $i++ ) {
            my $colname         = $columns[$i];
            unless ($colname) {
                $colname    = "c" . $empty_col_replace++;
                $log->error("EMPTY colname detected! replacing with $colname");
                $log->debug("table is: ".Dumper($table->as_HTML));
            }
            my $value           = $values[$i]->as_text;
            if ( $colname eq "MESSAGE_ID" ) {
                push @msg_id_entities, $value;
                $value = qq|<span class="entity message_id" data-entity-value="$value" data-entity-type="message_id">$value</span>|;
            }
            $rowres{$colname}   = $value;
        }
        push @results, \%rowres;
    }
    my $resultcount = scalar(@results);
    return \@results, \@columns, \@msg_id_entities;
}

__PACKAGE__->meta->make_immutable;
1;
