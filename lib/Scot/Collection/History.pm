package Scot::Collection::History;

use lib '../../../lib';
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

    my $target  = delete $href->{targets};

    my $obj = $self->create($href);

    # now link it to the object
    my $link = $env->mongo->collection('Link')->create_bidi_link({
        type   => "history",
        id     => $obj->id,
    },{
        type => $target->{type},
        id   => $target->{id},
    });

    unless ($obj) {
        $log->error("Failed to create History record for $href->{what}");
    }
}

1;
