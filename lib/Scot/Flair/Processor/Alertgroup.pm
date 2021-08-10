package Scot::Flair::Processor::Alertgroup;

use strict;
use warnings;
use utf8;
use lib '../../../../lib';

use Data::Dumper;
use HTML::Entities;
use SVG::Sparkline;
use Scot::Flair::Io;
use Try::Tiny;

use Moose;
extends 'Scot::Flair::Processor';

has sentinel_logo => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '/images/azure-sentinel.png',
);

sub flair_object {
    my $self        = shift;
    my $alertgroup  = shift;
    my $log         = $self->env->log;
    my $timer       = $self->env->get_timer("flair_object");
    my %results     = (); 
    my $agid        = $alertgroup->id;

    $log->debug("+++ [$$] flairing Alertgroup ".$agid);

    my $cursor  = $self->scotio->get_alerts($alertgroup);

    while (my $alert = $cursor->next) {
        $self->flair_alert(\%results, $alert);
    }
    
    &$timer;
    $log->trace("Alertgroup results: ",{filter=>\&Dumper, value=> \%results});
    $self->update_alertgroup(\%results, $agid);
    $log->debug("+++ [$$] done flairing Alertgroup ".$agid);
    return \%results;
}

sub flair_alert {
    my $self    = shift;
    my $results = shift;
    my $alert   = shift;
    my $log     = $self->env->log;
    my $timer   = $self->env->get_timer("flair_alert");

    if ( ref($alert) eq "Scot::Model::Alert") {
        $alert  = $alert->as_hash;
    }

    my $alertid = $alert->{id};
    my $agid    = $alert->{alertgroup};
    my $tracker = "{$agid:$alertid}";
    $log->debug("$tracker flair alert $alertid begins");

    my $alert_data  = $alert->{data};

    foreach my $column (keys %$alert_data) {
        my $aref    = $self->ensure_array($alert_data->{$column});
        my $cell = {
            cell_data   => $aref,
            colname     => $column,
            alert       => $alertid,
            alertgroup  => $agid,
        };
        my $tracker = "[$agid:$alertid";
        $self->flair_cell($results, $cell,$tracker);
    }
    $log->debug("$tracker flair alert $alertid ends");
}

sub ensure_array {
    my $self    = shift;
    my $data    = shift;
    my @values  = ();

    if ( ref($data) ne "ARRAY" ) {
        push @values, $data;
    }
    else {
        push @values, @{$data};
    }
    return wantarray ? @values : \@values;
}

sub flair_cell {
    my $self    = shift;
    my $results = shift;
    my $cell    = shift;
    my $tracker = shift;
    my $column  = $cell->{colname};
    my $alertid = $cell->{alert};
    my $log     = $self->env->log;

    $log->debug("___ begin flair_cell $alertid $column");

    if ( $self->is_skippable_column($column) ) {
        $results->{$alertid}->{$column}->{flair} = $cell->{cell_data};
        return;
    }

    if ( my $special = $self->process_special_columns($results, $cell) ) {
        $log->trace("special column processed: $column");
        return;
    }

    my $items = $cell->{cell_data};

    foreach my $item (@$items) {
        $self->flair_item($results, $alertid, $column, $item, $tracker);
    }
    $log->debug("___ end flair_cell $alertid $column");
    $log->trace("results->{$alertid}->{entities} after flair cell $column ",
                {filter=>\&Dumper, value => $results->{$alertid}->{entities}});
}

sub flair_item {
    my $self    = shift;
    my $results = shift;
    my $alertid = shift;
    my $column  = shift;
    my $item    = shift;
    my $tracker = shift;
    my $log     = $self->env->log;

    $log->trace("processing $alertid $column : $item");

    $tracker .= ":$column]";

    my $html    = '<html>'.
                  encode_entities($item).
                  '</html>';

    my $edb = $self->process_html($html, $tracker);

    my $found_flair     = $edb->{flair};
    my $plain_text      = $edb->{text};
    my $found_entities  = $edb->{entities};

    $log->trace("edb ",{filter=>\&Dumper, value => $edb});

    push @{$results->{$alertid}->{$column}->{flair}},$found_flair;
    push @{$results->{$alertid}->{$column}->{text}} ,$plain_text;
    
    $log->debug("Processing found entities");
    foreach my $type (keys %$found_entities) {
        $log->debug("    Type $type");
        foreach my $value (keys %{$found_entities->{$type}}) {
            $log->debug("        value $value");
             #note entites are up one level since we don't 
             #track to the cell/column 
            $results->{$alertid}->{entities}->{$type}->{$value}++;
        }
    }
    $log->trace("results after flair item ",{filter=>\&Dumper, value => $results});
}

sub is_skippable_column {
    my $self    = shift;
    my $column  = shift;

    if ( $column eq "columns" or
         $column eq "_raw" or 
         $column eq "search" ) {
        return 1;
    }
    return undef;
}

sub process_special_columns {
    my $self    = shift;
    my $results = shift;
    my $cell    = shift;

    return 1 if ( $self->process_msg_id_cell($results, $cell) ); 
    return 1 if ( $self->process_scanid_cell($results, $cell) );
    return 1 if ( $self->process_attachment_cell($results, $cell));
    return 1 if ( $self->process_sparkline_cell($results, $cell));
    return 1 if ( $self->process_sentinel_cell($results,$cell));
    return undef;
}

sub process_msg_id_cell {
    my $self    = shift;
    my $results = shift;
    my $cell    = shift;
    my $alertid = $cell->{alert};
    my $column  = $cell->{colname};
    my $items   = $cell->{cell_data};

    if ( $column =~ /message[_-]id/i ) {

        return 1;
    }
    return undef;
}
    
sub process_scanid_cell {
    my $self    = shift;
    my $results = shift;
    my $cell    = shift;
    my $alertid = $cell->{alert};
    my $column  = $cell->{colname};
    my $items   = $cell->{cell_data};

    if ( $column =~ /^(lb){0,1}scanid$/i ) {
        foreach my $item (@$items) {
            push @{$results->{$alertid}->{$column}->{flair}},
                $self->genspan($item, "uuid1");
            push @{$results->{$alertid}->{$column}->{text}}, $item;
            $results->{$alertid}->{entities}->{uuid1}->{$item}++;
            
        }
        return 1;
    }
    return undef;
}

sub process_attachment_cell {
    my $self    = shift;
    my $results = shift;
    my $cell    = shift;
    my $alertid = $cell->{alert};
    my $column  = $cell->{colname};
    my $items   = $cell->{cell_data};

    if ( $column =~ /^attachment[_-]name/i or
         $column =~ /^attachments$/i ) {

        foreach my $item (@$items) {
            push @{$results->{$alertid}->{$column}->{flair}},
                $self->genspan($item, "filename");
            push @{$results->{$alertid}->{$column}->{text}}, $item;
            $results->{$alertid}->{entities}->{filename}->{$item}++;
        }
        return 1;
    }
    return undef;
}

sub process_sparkline_cell {
    my $self    = shift;
    my $results = shift;
    my $cell    = shift;
    my $log     = $self->env->log;
    my $alertid = $cell->{alert};
    my $column  = $cell->{colname};
    my $items   = $cell->{cell_data};

    if ( ref($items) ne 'ARRAY' ) {
        if ( $items !~ /^##__SPARKLINE__##/ ) {
            $log->trace("string cell data does not begin with ##__SPARKLINE");
            return undef;
        }
        $items  = $self->convert_to_sparkline_array($items);
    }
    else {
        if ( $items->[0] ne "##__SPARKLINE__##" ) {
            $log->trace("cell[0] is not a sparkline header");
            return undef;
        }
    }

    $log->debug("Processing SPARKLINE cell items= ",{filter=>\&Dumper, value => $items});
    my $head    = shift @$items;

    $log->debug("found a sparkline data cell");
    $log->trace("value => ",{filter=>\&Dumper, value=>$items});

    my @vals = grep {/\S+/} @$items;    # weed out " "

    my $svg = SVG::Sparkline->new(
        Line => {
            values  => \@vals,
            color   => 'blue',
            height  => 12,
        }
    );
    push @{$results->{$alertid}->{$column}->{flair}}, $svg->to_string;
    push @{$results->{$alertid}->{$column}->{text}}, $items;
    return 1;
}

sub convert_to_sparkline_array {
    my $self    = shift;
    my $items   = shift;
    my @new     = split(',',$items);
    return wantarray ? @new : \@new;
}

sub process_sentinel_cell {
    my $self    = shift;
    my $results = shift;
    my $cell    = shift;
    my $alertid = $cell->{alert};
    my $column  = $cell->{colname};
    my $items   = $cell->{cell_data};

    if ($column =~ /sentinel_incident_url/i) {

        foreach my $item (@$items) {
            my $image   = HTML::Element->new(
                'img',
                'alt', 'view in Azure Sentinel',
                'src', $self->sentinel_logo,
            );
            my $anchor  = HTML::Element->new(
                'a',
                'href'      => $item,
                'target'    => '_blank',
            );
            $anchor->push_content($image);
            push @{$results->{$alertid}->{$column}->{flair}}, $anchor->as_HTML;
            push @{$results->{$alertid}->{$column}->{text}}, $anchor->as_text;
        }
        return 1;
    }
    return undef;
}

sub update_alertgroup {
    my $self    = shift;
    my $results = shift;
    my $agid    = shift;
    my $io      = $self->scotio;
    my $log     = $self->env->log;

    my %new_ag_data = ();
    my %ag_edb      = ();

    $log->debug("update_alertgroup $agid");

    foreach my $alert_id (sort keys %$results) {

        my $edb = $results->{$alert_id}->{entities};

        foreach my $type (keys %$edb) {
            foreach my $value (keys %{$edb->{$type}}) {
                $ag_edb{$type}{$value}++;
            }
        }

        $io->update_alert($alert_id, $results);

    }

    $io->update_alertgroup($agid, \%ag_edb);
    
}

1;
