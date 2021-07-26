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

    $log->debug("+++ [$$] flairing RemoteFlair Request".$remflair->id);

    my $body = $self->preprocess_body($remflair);
    my $results = $self->process_html($body);

    $self->update_remoteflair($remflair, $results);
    $log->debug("+++ [$$] done flairing RemoteFlair Request".$remflair->id);

    return $results;
}

sub preprocess_body {
    my $self        = shift;
    my $remflair    = shift;
    my $body        = $remflair->html;
    return $body;
}

sub update_remoteflair {
    my $self    = shift;
    my $rfobj   = shift;
    my $results = shift;
    my $io      = $self->scotio;

    $io->update_remoteflair($rfobj, $results);
}


1;
