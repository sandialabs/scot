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
    my $remflair = shift;
    my $log     = $self->env->log;

    $log->debug("[$$] flairing RemoteFlair Request".$remflair->id);

    my $body = $self->preprocess_body($remflair);
    my $results = $self->process_html($body);

    $self->update_entry($remflair, $results);

    return $results;
}

sub preprocess_body {
    my $self        = shift;
    my $remflair    = shift;
    my $body;
    
    # todo: any pre-processing that might be necessary

    return $body;
}

sub update_entry {
    my $self    = shift;
    my $entry   = shift;
    my $results = shift;

    # pull results out 
    # update remote_flair via scotio

}


1;
