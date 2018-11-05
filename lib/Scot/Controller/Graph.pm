package Scot::Controller::Graph;

use Data::Dumper;
# use v5.18;
use strict;
use warnings;
use base 'Mojolicious::Controller';


sub get_graph {
    my $self    = shift;
    my $type    = $self->stash('thing');
    my $id      = $self->stash('id');
    my $depth   = $self->stash('depth');
    my $params  = $self->req->params->to_hash;

    my %db  = ();
    my $target  = { type => $type, id => $id };

    $self->build_graph(\%db, $target, $depth);
    $self->rendergraph(\%db);
}

sub build_graph {
    my $self    = shift;
    my $dbhref  = shift;
    my $target  = shift;
    my $depth   = shift;

    if ( $depth == 0 ) {
        return;
    }

    my $cursor  = $self->get_links($target);
    my @newnode = ();
    while ( my $link = $cursor->next ) {
        $self->conditionally_add_to_graph($link, $dbhref, \@newnode);
    }
    $depth--;
    foreach my $newnode (@newnode) {
        $self->build_graph($dbhref, $newnode, $depth);
    }
}

sub get_links {
    my $self    = shift;
    my $target  = shift;
    my $filter  = [qw(alert)];

    my $cursor  = $self->env->mongo->collection('Link')
                        ->get_links_by_target($target, $filter);
    return $cursor;
}

sub conditionally_add_to_graph {
    my $self    = shift;
    my $link    = shift;
    my $dbhref  = shift;
    my $naref   = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my ( $v0, $v1 ) = @{$link->vertices};

    if ( my $n0 = $self->ok_to_add_node($dbhref, $v0) ) {
        $self->add_node($v0, $n0, $dbhref);
        push @$naref, $v0;
    }

    if ( my $n1 = $self->ok_to_add_node($dbhref, $v1) ) {
        $self->add_node($v1, $n1, $dbhref);
        push @$naref, $v1;
    }

    if ( my $edge = $self->ok_to_add_edge($dbhref, $v0, $v1) ) {
        $self->add_edge($dbhref, $edge, $v0, $v1);
    }
}

sub ok_to_add_node {
    my $self    = shift;
    my $dbhref  = shift;
    my $v       = shift;
    my $k       = $v->{type}."_".$v->{id};
    if ( defined $dbhref->{nodes}->{$k} ) {
        return undef;
    }
    my $n       = $self->get_vertice($v);
    if ( ! defined $n ) {
        return undef;
    }
    if ( $self->node_filtered($n) ) {
        return undef;
    }
    return $n;
}

sub node_filtered {
    my $self    = shift;
    my $node    = shift;
    my $filters = $self->env->graph_entity_filter;

    if ( ref($node) eq "Scot::Model::Entity" ) {
        if ( $node->status eq "untracted" ) {
            return 1;
        }
    }
    if ( grep { /^$node->value$/i } @$filters ) {
        return 1;
    }
    return undef;
}

sub get_degree {
    my $self    = shift;
    my $node    = shift;
    my $count   = $self->env->mongo->collection('Link')
                       ->get_display_count($node);
    return $count;
}

sub ok_to_add_edge {
    my $self    = shift;
    my $dbhref  = shift;
    my $v0      = shift;
    my $v1      = shift;

    my $key = $v0->{type} . "-".
              $v0->{id}. "_" .
              $v1->{type} . "-".
              $v1->{id};

    if ( defined $dbhref->{edges}->{$key} ) {
        return undef;
    }
    return $key;
}

sub add_edge {
    my $self    = shift;
    my $dbhref  = shift;
    my $edge    = shift;
    my $v0      = shift;
    my $v1      = shift;
    $dbhref->{edges}->{$edge} = {
        id      => $edge,
        from    => $self->get_key($v0),
        to      => $self->get_key($v1),
    };
}

sub get_vertice {
    my $self    = shift;
    my $vertex  = shift;
    my $type    = $vertex->{type};
    my $id      = $vertex->{id};
    my $mongo   = $self->env->mongo;
    my $node    = $mongo->collection(ucfirst($type))->find_iid($id);
    return $node;
}

sub rendergraph {
    my $self    = shift;
    my $dbhref  = shift;

}

sub add_node {
    my $self    = shift;
    my $dbhref  = shift;
    my $vertex  = shift;
    my $node    = shift;

    my $key     = $vertex->{type} . "_" . $vertex->{id};
    my $degree  = $self->get_degree($node);

    $dbhref->{nodes}->{$key} = {
        id      => $key,
        label   => $self->get_label($node, $vertex, $degree),
        shape   => $self->get_shape($vertex),
        color   => $self->get_color($vertex),
        title   => $key,
        degree  => $degree,
        data    => { },
    };
}

sub get_label {
    my $self    = shift;
    my $node    = shift;
    my $vertex  = shift;
    my $degree  = shift;

    my $type    = $vertex->{type};
    my $id      = $vertex->{id};

    if ( $type  eq "entity" ) {
        return "[$id]\n".$node->value."\n{$degree}";
    }
    if ( grep {/$type/} (qw(entry event intel incident guide checklist)) ) {
        return "[$id]\n".$node->subject."\n{$degree}";
    }
    return "$type $id";
}

sub get_color {
    my $self    = shift;
    my $vertex  = shift;
    my $type    = $vertex->{type};
    if ( $type eq "entry" ) {
        return "#FFFF00";
    }
    if ( $type eq "entity" ) {
        return "#C2FABC";
    }
    return "#97C2FC";
}
    
sub get_shape {
    my $self    = shift;
    my $node    = shift;
    if ( $node->{type} eq "entry" ) {
        return "diamond";
    }
    if ( $node->{type} eq "entity" ) {
        return "box";
    }
    return "box";
}

1;
