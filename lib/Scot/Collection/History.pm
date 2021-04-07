package Scot::Collection::History;

use lib '../../../lib';
use Data::Dumper;
use Moose 2;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTargeted
);

# tag creation or update
sub create_from_handler {
    my $self    = shift;
    my $handler = shift;
    my $env     = $handler->env;
    my $log     = $env->log;

    $log->trace("create in API Scot::Collection::History not supported");
    return undef;
}

sub add_history_entry {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $target  = $href->{target}; # { id => x, type => y }

    $log->trace("history is ",{filter=>\&Dumper, value=>$href});
    $log->debug("adding history to $target->{type} $target->{id}");

    my $obj     = $self->create($href);
    unless ($obj) {
        $log->error("Failed to create History record for $href->{what}");
        return;
    }

}


1;
