package Scot::Flair::Processor::Remoteflair;

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

    my $body = $self->process_images($entry );
    my $results = $self->process_html($body);

    $self->update_entry($entry, $results);

    return $results;
}

sub update_entry {
    my $self    = shift;
    my $entry   = shift;
    my $results = shift;

    # pull results out 
    # update entry via scotio

}


1;
