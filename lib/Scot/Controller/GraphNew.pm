package Scot::Controller::Graph;

use Data::Dumper;
use Try::Tiny;
use DateTime;
use Mojo::JSON qw(decode_json encode_json);
# use v5.18;
use strict;
use warnings;
use base 'Mojolicious::Controller';

sub get_graph {
    my $self    = shift;
    my $type    = $self->stash('thing');
    my $id      = $self->stash('id');
    my $depth   = $self->stash('depth');

    my %db      = ();
    my $target  = {
        type    => $type,
        id      => $id
    };

    $self->build_graph(\%db, $target, $depth, 1);
    $self->render(json => {
        nodes   => $db{nodes},
        edges   => $db{edges},
    });
}

sub build_graph {
    my $self    = shift;
    my $dbhref  = shift;
    my $target  = shift;
    my $depth   = shift;
    my $index   = shift;

    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;
    my $type    = $target->{type};
    my $id      = $target->{id};

    $log->debug("building graph");
    $log->debug("    depth : $depth");
    $log->debug("    target: $type $id");

    if ( $depth < 0 ) {
        $log->debug("done recursing");
        return;
    }

    
    my @newnodes    = ();
    my $link_cursor = $mongo->collection('Link')->get_links_by_target($target);
    
    while ( my $link = $link_cursor->next ) {

        my @tolink  = ();
        foreach my $node (@{$link->vertices}) {
            my $key = $node->{target}. " " .$node->{id};
            unless (defined $dbhref->{seen}->{nodes}->{$key} ) {
                # new node
                $index++;
                $dbhref->{seen}->{nodes}->{$key} = $index;
                push @{$dbhref->{nodes}},{
                    id      => $index,
                    label   => $self->get_label($node),
                };
                push @tolink, $index;
                push @newnodes, $node;
            }
            else {
                push @tolink, $dbhref->{seen}->{nodes}->{$key};
            }
        }

        my $ekey = join(' ',@tolink);
        unless (defined $dbhref->{seen}->{edges}->{$ekey} ) {
            $dbhref->{seen}->{edges}->{$ekey}++;
            push @{$dbhref->{edges}}, {
                from    => $tolink[0],
                to      => $tolink[1],
            };
        }
    }

    # now get new nodes and repeat if additonal depth needed
    foreach my $newnode (@newnodes) {
        $self->build_graph($dbhref, $newnode, $depth--, $index);
    }
}
1;
