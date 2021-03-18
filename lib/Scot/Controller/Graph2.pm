package Scot::Controller::Graph2;

use Try::Tiny;
use Data::Dumper;
use DateTime;
use Mojo::JSON qw(decode_json encode_json);
use strict;
use warnings;
use base 'Mojolicious::Controller';

sub get_graph {
    my $self           = shift;
    my $target_type    = $self->stash('thing');
    my $target_id      = $self->stash('id') + 0;
    my $depth          = $self->stash('depth');
    my $log            = $self->env->log;

    $log->debug("get_graph");

    my $db  = {};
    my $target  = {
        type    => $target_type,
        id      => $target_id,
    };

    $self->build_graph($db, $target, $depth);
    # $log->debug("DB ",{filter=>\&Dumper, value=> $db});
    $self->add_degree($db);
    my $code = 200;
    my $href = {
        nodes   => $db->{nodes},
        links   => $db->{links},
    };
    $self->render(
        status  => $code,
        json    => $href,
    );
}

sub add_degree {
    my $self    = shift;
    my $db      = shift;
    
    foreach my $node (@{$db->{nodes}}) {
        my $node_id = $node->{id};
        $node->{degree} = $db->{degree}->{$node_id};
    }
}

sub build_graph {
    my $self        = shift;
    my $db          = shift;
    my $target      = shift;
    my $depth       = shift;
    my $log         = $self->env->log;

    my $target_type = $target->{type};
    my $target_id   = $target->{id};
    $log->debug("build_graph(db, {type => $target_type, id => $target_id}, $depth)");

    if ( $depth < 1 ) {
        return;
    }

    my $cursor      = $self->get_link_cursor($target);
    my @new_nodes   = ();

    while ( my $link = $cursor->next ) {
        $self->add_vertices_to_graph($link, $db);
    }

    my $new_nodes_aref = delete $db->{new};
    if (! defined $new_nodes_aref ) {
        $new_nodes_aref = [];
    }
    $log->debug("Added ".scalar(@$new_nodes_aref)." nodes at depth $depth");
    $depth--;
    foreach my $target (@$new_nodes_aref) {
        $self->build_graph($db, $target, $depth);
    }
}

sub add_vertices_to_graph {
    my $self    = shift;
    my $link    = shift;
    my $db      = shift;

    if ( $self->filter_vertex($db, $link) ) {
        return;
    }

    my @links   = ();
    for (my $i = 0; $i < scalar(@{$link->vertices}); $i++) {
        my $vertex  = $link->vertices->[$i];
        my $value   = $link->memo->[$i];
        my $vid     = $self->add_to_db_if_missing($db, $vertex, $value);
        push @links, $vid;
    }
    push @{$db->{links}}, { source => $links[0], target => $links[1] };
    $db->{degree}->{$self->build_node_id($link,0)}++;
    $db->{degree}->{$self->build_node_id($link,1)}++
}

sub build_node_id {
    my $self    = shift;
    my $link    = shift;
    my $index   = shift;

    my $id = join('_',
        $link->vertices->[$index]->{type},
        $link->vertices->[$index]->{id},
    );
    return $id;
}

sub filter_vertex {
    my $self    = shift;
    my $db      = shift;
    my $link    = shift;
    my $log     = $self->env->log;

    for (my $i = 0; $i < scalar(@{$link->vertices}); $i++) {
        my $vertex  = $link->vertices->[$i];
        my $node_id = $self->build_node_id($link, $i);
        if ( $vertex->{type} eq "entity" ) {
            if ( $db->{degree}->{$node_id} > 75 ) {
                $log->debug("High degree entity $vertex->{id} filtered");
                return 1;
            }
        }
    }
    return undef;
}
    
sub add_to_db_if_missing {
    my $self        = shift;
    my $db          = shift;
    my $vertex      = shift;
    my $vertex_val  = shift;

    my $vertex_id   = join('_', $vertex->{type}, $vertex->{id});
    my $vertex_name = $vertex_id; 

    if ( defined $db->{seen}->{$vertex_id} ) {
        return $vertex_id;
    }


    push @{$db->{nodes}}, {
        id      => $vertex_id,
        name    => $vertex_name,
        val     => $vertex_val,
        target_type    => $vertex->{type},
        target_id      => $vertex->{id},
    };
    $db->{seen}->{$vertex_id}++;
    push @{$db->{new}}, { type => $vertex->{type}, id => $vertex->{id} };
    return $vertex_id;
}

sub get_link_cursor {
    my $self        = shift;
    my $target      = shift;
    my $mongo       = $self->env->mongo;
    my $collection  = $mongo->collection('Link');
    return $collection->get_links_by_target($target, 1);
}

1;
