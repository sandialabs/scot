package Scot::App::Responder::Watch;

use Data::Dumper;
use Try::Tiny;
use Moose;
extends 'Scot::App::Responder';

has name    => (
    is      => 'ro',
    isa     => 'Str',
    required    => 1,
    default => 'Flair',
);


sub process_message {
    my $self    = shift;
    my $pm      = shift;
    my $href    = shift;
    my $log     = $self->log;

    $log->debug("refreshing entitytypes");
    $self->env->regex->load_entitytypes;

    my $action  = lc($href->{action});
    my $type    = lc($href->{data}->{type});
    my $id      = $href->{data}->{id} + 0;
    my $who     = $href->{data}->{who};
    my $opts    = $href->{data}->{opts};

    $log->debug("[Wkr $$] Processing message $action $type $id from $who");

    # place logic here to take actions based on the message received.
    # 
    # like if you want to be notified when a certain event is updated
    # you could do:
    # if ( $action eq "updated" ) {
    #     if ( $id == 123 ) {
    #         $self->do_something();
    #     }
    # }
    # obviously we want to put these actions in a config file
    # or possibly a database collection that get's loaded at daemon start.

    my $action  = $self->get_action($href);

    &$action($href);

}

sub get_action {
    my $self    = shift;
    my $href    = shift;

    # get action match based on href
    my $action  = $self->lookup_action($href);
    my $coderef = $self->build_sub_from($action);

    return $coderef;
}

1;
