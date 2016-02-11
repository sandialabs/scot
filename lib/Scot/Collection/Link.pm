package Scot::Collection::Link;

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

sub add_link {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $obj = $self->create($href);

    unless ($obj) {
        $log->error("Failed to create Link record for ", 
                    { filter =>\&Dumper, value => $href });
    }
    return $obj;
}

sub get_links {
    my $self    = shift;
    my %params  = @_;

    # can be any/all of the following
    # %params = (
    #   item_type   => "foo",
    #   item_id     => 12,
    #   when        => epoch (or range)
    #   target_type => "bar",
    #   target_id   => 234,
    # );

    my $cursor  = $self->find(\%params);
    return $cursor;
}

sub get_links_for {
    my $self    = shift;
    my $object  = shift;
    my $colname = $object->get_collection_name();

    my $cursor  = $self->find({
        target_type => $colname,
        target_id   => $object->id,
    });
    return $cursor;
}

sub remove_links {
    my $self    = shift;
    my %params  = @_;

    my $cursor  = $self->find(\%params);
    while ( my $link = $cursor->next ) {
        $link->remove;
    }
    return;
}


=item B<create_bidi_link>

This function is used to create bidi links between objects 
since the link collection is directional, this means creating 
two documents one with obj a as the item and as target.

=cut

sub create_bidi_link {
    my $self    = shift;
    my $a_href  = shift;
    my $b_href  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $now     = $env->now;
    my $when    = shift // $now;

    my $link_ab = {
        item_type   => $a_href->{type},
        item_id     => $a_href->{id},
        when        => $when,
        target_type => $b_href->{type},
        target_id   => $b_href->{id},
    };
    my $link_ba   = {
        item_type   => $b_href->{type},
        item_id     => $b_href->{id},
        when        => $when,
        target_type => $a_href->{type},
        target_id   => $a_href->{id},
    };
    my $errors = 0;
    foreach my $href ($link_ab, $link_ba) {
        my $link    = $self->add_link($href);
        unless ( $link ) {
            $log->error("Failed creating link from ".
                        $href->{item_type}." to ".
                        $href->{target_type});
            $errors++;
        }
    }
    if ( $errors > 0 ) {
        return undef;
    }
    return 1;
}

sub remove_bidi_links {
    my $self    = shift;
    my $a       = shift;    # href { id , type }
    my $b       = shift;    # the other one

    my $link_ab = {
        item_type   => $a->{type},
        item_id     => $a->{id},
        target_type => $b->{type},
        target_id   => $b->{id},
    };
    my $link_ba = {
        item_type   => $b->{type},
        item_id     => $b->{id},
        target_type => $a->{type},
        target_id   => $a->{id},
    };
    foreach my $href ($link_ab, $link_ba) {
        $self->remove_links($href);
    }
}

sub find_any {
    my $self    = shift;
    my $a       = shift; # href = { id => x, type => y }
    my $b       = shift; # href = { id => x, type => y }

    my $match   = {
        '$or'   => [
            { target_type   => $a->{type},
              target_id     => $a->{id},
              item_type     => $b->{type},
              item_id       => $b->{id},
            },
            { target_type   => $b->{type},
              target_id     => $b->{id},
              item_type     => $a->{type},
              item_id       => $a->{id},
            },
        ]
    };
    my $cursor  = $self->find($match);
    return $cursor;
}

sub find_any_one {
    my $self    = shift;
    my $a       = shift; # href = { id => x, type => y }
    my $b       = shift; # href = { id => x, type => y }

    my $match   = {
        '$or'   => [
            { target_type   => $a->{type},
              target_id     => $a->{id},
              item_type     => $b->{type},
              item_id       => $b->{id},
            },
            { target_type   => $b->{type},
              target_id     => $b->{id},
              item_type     => $a->{type},
              item_id       => $a->{id},
            },
        ]
    };
    my $object  = $self->find_one($match);
    return $object;
}

1;
