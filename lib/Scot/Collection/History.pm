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
    my $link = $env->mongo->collection('Link')->add_link({
        item_type   => "history",
        item_id     => $obj->id,
        when        => $env->now(),
        target_type => $target->{type},
        target_id   => $target->{id},
    });

    unless ($obj) {
        $log->error("Failed to create History record for $href->{what}");
    }
}

sub get_history {
    my $self    = shift;
    my %params  = @_;

    my $id      = $params{target_id};
    my $thing   = $params{target_type};

    my $cursor  = $self->find({
        targets => {
            '$elemMatch' => {
                type => $thing,
                id   => $id,
            },
        },
    });
    my $count   = $cursor->count;
    return $cursor;
}



1;
