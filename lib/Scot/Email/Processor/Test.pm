package Scot::Email::Processor::Test;

use Data::Dumper;
use Moose;
extends 'Scot::Email::Processor';

sub run {
    my $self    = shift;
    my $mbox    = shift;
    my $log     = $self->env->log;

    $log->debug(__PACKAGE__." is running.");

}

1;
