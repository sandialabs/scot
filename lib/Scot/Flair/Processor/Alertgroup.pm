package Scot::Flair::Processor::Alertgroup;

use strict;
use warnings;
use utf8;
use lib '../../../../lib';

use Data::Dumper;
use HTML::Entities;
use SVG::Sparkline;
use Scot::Flair::Io;

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
    my @results     = ();

    $log->debug("[$$] flairing Alertgroup ".$alertgroup->id);

    my $cursor  = $self->scotio->get_alerts($alertgroup);

    while (my $alert = $cursor->next) {
        my $newalertdata = $self->flair_alert($alert);
        push @results, $self->update_alert($alert, $newalertdata);
    }

    &$timer;
    return \@results;
}

sub flair_alert {
    my $self    = shift;
    my $alert   = shift;
    my $log     = $self->env->log;
    my $timer   = $self->env->get_timer("flair_alert");

    $log->debug("[$$] working alert ".$alert->id);

    my $flair   = {                         # build and hold data extracted
        # flair => holds flaired text
        # seen => keeps track of seen entities
        # entities => array of { type: x, value: y } entities
    };               
    my $data    = $alert->data;

    if ( ! defined $data ) {
        $log->error("[$$] Alert ".$alert->id." missing data");
        return $flair;
    }

    KEY:
    foreach my $key (keys %{$data}) {

        next KEY if ( $key eq "columns" );

        $log->debug("Retrieving values in column $key");

        my @values = $self->get_key_values($data, $key);
        $self->flair_key_values($key, $flair, @values);

    }
    &$timer;
    return {
        data_with_flair => $flair->{flair},
        entities        => $flair->{entities},
        parsed          => 1,
    };
}

sub flair_key_values {
    my $self    = shift;
    my $key     = shift;
    my $flair   = shift;
    my @values  = @_;

    VALUE:
    foreach my $value (@values) {

        if ( $key =~ /message[_-]id$/i ) {
            $self->process_msg_id_cell($key, $flair, $value);
            next VALUE;
        }

        if ( $key =~ /^(lb){0,1}scanid$/i ) {
            $self->process_scanid_cell($key, $flair, $value);
            next VALUE;
        }

        if ( $key =~ /^attachment[_-]name/i or
             $key =~ /^attachments$/ ) {
            $self->process_attachment_cell($key, $flair, $value);
            next VALUE;
        }

        if ( $key =~ /^columns$/i ) {
            $self->append_flair($flair, $key, $value);
            next VALUE;
        }

        if ( $key =~ /^sparkline$/i or
             grep {/__SPARKLINE__/} @values ) {
            $self->process_sparkline_cell($flair, $key, @values);
            return; # sparkline gobbles up entire @values array, so we are done
        }

        if ( $key =~ /sentinel_incident_url/i ) {
            $self->process_sentinel_cell($key, $flair, $value);
            return; # only every one in cell
        }

        # default
        $self->env->log->debug("Default Cell Processing");
        my $html    = '<html>'.encode_entities($value).'</html>';
        my $results = $self->process_html($html);

        foreach my $entity_href (@{$results->{entities}}) {
            if ( $self->value_not_seen($flair, $entity_href->{value}) ) {
                $self->add_entity($flair, $entity_href);
            }
        }
        $self->append_flair($flair, $key, $results->{flair});
    }
}

sub process_html {
    my $self    = shift;
    my $html    = shift;
    return $self->extractor->process_html($html);
}


sub value_not_seen {
    my $self    = shift;
    my $flair   = shift;
    my $value   = shift;

    if ( ! defined $flair->{seen}->{$value} ) {
        $flair->{seen}->{$value}++; # now it's seen
        return 1;
    }
    # we've seen it
    return undef;
}

sub add_entity {
    my $self    = shift;
    my $flair   = shift;
    my $href    = shift;
    push @{ $flair->{entities} }, $href;
}

sub append_flair {
    my $self    = shift;
    my $flair   = shift;
    my $key     = shift;
    my $new     = shift;
    my $existing = $flair->{flair}->{$key};
    my $union   = $self->merge_flair($new, $existing);

    $flair->{flair}->{$key} = $union;
}

sub merge_flair {
    my $self    = shift;
    my $new     = shift;
    my $existing = shift;

    return $new if ( ! defined $existing );
    return $new if ( $existing eq '');
    return $existing . " " . $new;
}

sub process_sentinel_cell {
    my $self    = shift;
    my $key     = shift;
    my $flair   = shift;
    my $value   = shift;

    $self->env->log->debug("process_sentinel_cell");

    my $image   = HTML::Element->new(
        'img',
        'alt', 'view in Azure Sentinel',
        'src', $self->sentinel_logo
    );
    my $anchor  = HTML::Element->new(
        'a',
        'href', => $value,
        'target'=> '_blank',
    );
    $anchor->push_content($image);
    $self->append_flair($flair, $key, $anchor->as_HTML);
}

sub process_sparkline_cell {
    my $self    = shift;
    my $key     = shift;
    my $flair   = shift;
    my @values   = @_;
    my $log     = $self->env->log;

    $log->debug("[$$] creating sparkline");

    my $head    = shift @values;
    if ( $head eq "##__SPARKLINE__##" ) {
        my $svg = SVG::Sparkline->new(
            Line => {
                value => \@values,
                color => 'blue',
                height => 12
            }
        );
        $self->append_flair($flair, $key, $svg);
    }
}

sub process_attachment_cell {
    my $self    = shift;
    my $key     = shift;
    my $flair   = shift;
    my $value   = shift;

    $self->env->log->debug("process_attachement_cell");

    if ($value eq "" or $value eq " ") {
        return;
    }

    my ($entity_ref, $flairtxt) = $self->process_cell($value, "filename");
    if ( $self->value_not_seen($flair, $entity_ref->{value}) ) {
        $self->add_entity($flair, $entity_ref);
    }
    $self->append_flair($flair, $key, $flairtxt);
}

sub process_scanid_cell {
    my $self    = shift;
    my $key     = shift;
    my $flair   = shift;
    my $value   = shift;

    $self->env->log->debug("process_scanid_cell");

    my ($entity_ref, $flairtxt) = $self->process_cell($value, "message_id");

    if ( $self->value_not_seen($flair, $entity_ref->{value}) ) {
        $self->add_entity($flair, $entity_ref);
    }
    $self->append_flair($flair, $key, $flairtxt);


sub process_msg_id_cell {
    my $self    = shift;
    my $key     = shift;
    my $flair   = shift;
    my $value   = shift;
    $value =~ s/[\<\>]//g;  # remove angle quotes from msg id

    $self->env->log->debug("process_msg_id_cell");

    my ($entity_ref, $flairtxt) = $self->process_cell($value, "message_id");

    if ( $self->value_not_seen($flair, $entity_ref->{value}) ) {
        $self->add_entity($flair, $entity_ref);
    }
}

sub get_key_values {
    my $self    = shift;
    my $data    = shift;
    my $key     = shift;
    my $log     = $self->env->log;

    if ( ref($data->{$key}) ne "ARRAY" ) {
        $log->warn("$key does not hold array, pushing it into one");
        $data->{$key} = [ $data->{$key} ];
    }
    my @values = @{$data->{$key}};
    $log->debug("value = ",{filter=>\&Dumper, value=>\@values});
    return wantarray ? @values : \@values;
}

sub update_alert {
    my $self    = shift;
    my $alert   = shift;
    my $newdata = shift;


}

sub send_notification {
    my $self    = shift;
    my $results = shift; # array ref

}

sub process_cell {
    my $self    = shift;
    my $text    = shift;
    my $header  = shift;

    $text = encode_entities($text);
    my $flair   = $self->genspan($text, $header);
    my $href    = {
        value   => $text,
        type    => $header,
    };
    return $href, $flair;
}
}





1;
