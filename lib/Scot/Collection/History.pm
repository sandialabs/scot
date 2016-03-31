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

    my $target  = delete $href->{targets};

    $log->debug("adding history to ",{filter=>\&Dumper, value=>$target});

    my $obj     = $self->create($href);
    unless ($obj) {
        $log->error("Failed to create History record for $href->{what}");
        return;
    }

    # now link it to the object
    my $src  = {
        type    => "history",
        id      => $obj->id,
    };

    $log->debug("src = ", { filter =>\&Dumper, value =>$src });

    if ( ref($target) eq "ARRAY" ) {
        foreach my $dhref (@$target) {
            my $dst = {
                type    => $dhref->{type},
                id      => $dhref->{id},
            };
            $log->debug("dst = ", { filter =>\&Dumper, value =>$dst });
            my $link = $env->mongo->collection('Link')->create_link($src,$dst);
        }
    }
    else {
        my $dst = {
            type    => $target->{type},
            id      => $target->{id},
        };
        $log->debug("dst = ", { filter =>\&Dumper, value =>$dst });
        my $link = $env->mongo->collection('Link')->create_link($src,$dst);
    }

}

1;
