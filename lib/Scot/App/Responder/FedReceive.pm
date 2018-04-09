package Scot::App::Responder::FedReceive;

use Data::Dumper;
use HTML::Entities;
use Try::Tiny;
use Moose;
extends 'Scot::App::Responder';

has name    => (
    is      => 'ro',
    isa     => 'Str',
    required    => 1,
    default => 'FedReceive',
);

sub process_message {
    my $self    = shift;
    my $pm      = shift;
    my $href    = shift;
    my $log     = $self->log;

    $log->debug("pm : ",{filter=>\&Dumper, value=>$pm});
    $log->debug("processing message: ",{filter=>\&Dumper, value=>$href});

}


1;
