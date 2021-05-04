package Scot::Flair::Processor::Entry;

use strict;
use warnings;
use utf8;
use lib '../../../../lib';

use Data::Dumper;
use Scot::Flair::Io;

use Moose;
extends 'Scot::Flair::Processor';

sub flair_object {
    my $self    = shift;
    my $entry   = shift;
    my $log     = $self->env->log;

    $log->debug("[$$] flairing Entry ".$entry->id);

    my $body    = $entry->body;
    my $results = $self->process_html($body);

    $self->update_entry($entry, $results);

    return $results;
}

sub update_entry {
    my $self    = shift;
    my $entry   = shift;
    my $results = shift;
    my $io      = $self->scotio;
    my $log     = $self->env->log;

    $log->debug("[$$] updating Entry ".$entry->id);

    $io->update_entry($entry, $results);

    foreach my $entity_href (@{$results->{entities}}) {
        $log->debug("updating entity ",{filter=>\&Dumper, value => $entity_href});
        $io->update_entity($entry, $entity_href);
    }
}


1;
