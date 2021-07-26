package Scot::Flair::Processor::Entry;

use strict;
use warnings;
use utf8;
use lib '../../../../lib';

use Data::Dumper;
use Scot::Flair::Io;
use Scot::Flair::Imgmunger;

use Moose;
extends 'Scot::Flair::Processor';

sub flair_object {
    my $self    = shift;
    my $entry   = shift;
    my $log     = $self->env->log;
    
    $log->debug("+++ [$$] flairing Entry ".$entry->id);

    my $body    = $self->preprocess_body($entry);
    my $results = $self->process_html($body);

    $self->update_entry($entry, $body, $results);
    $log->debug("+++ [$$] done flairing Entry ".$entry->id);

    return $results;
}

sub update_entry {
    my $self    = shift;
    my $entry   = shift;
    my $body    = shift;
    my $results = shift;
    my $io      = $self->scotio;
    my $log     = $self->env->log;

    $log->debug("[$$] updating Entry ".$entry->id);

    $io->update_entry($entry, $body, $results);

    foreach my $entity_type (keys %{$results->{entities}}) {

        foreach my $value (keys %{$results->{entities}->{$entity_type}}) {

            my $entity_href = { 
                type    => $entity_type, 
                value   => $value,
            };
            $io->update_entity($entry, $entity_href);
        }
    }
}

sub preprocess_body {
    my $self    = shift;
    my $entry   = shift;
    my $body    = $entry->body;
    my $log     = $self->env->log;

    $log->debug("preprocessing $body");

    # the body html may contain images with src's outside of scot
    # this can be a source of data leakage.  Imgmunger will download
    # external sources and create files for datauri images.

    my $munger = Scot::Flair::Imgmunger->new({
        env     => $self->env, 
        scotio  => $self->scotio
    });
    my $newhtml = $munger->process_body($entry->id, $body);

    return $newhtml;
}

1;
