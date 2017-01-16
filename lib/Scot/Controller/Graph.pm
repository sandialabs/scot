package Scot::Controller::Graph;


=head1 Name

Scot::Controller::Graph

=head1 Description

generate data sets suitable for force directed graph display

=cut

use Data::Dumper;
use Try::Tiny;
use DateTime;
use Mojo::JSON qw(decode_json encode_json);
use Data::Dumper::HTML qw(dumper_html);
use List::MoreUtils qw(uniq);
use strict;
use warnings;
use base 'Mojolicious::Controller';

=head1 Routes

=over 4

=item I<GET> /graph

=cut

sub get_graph {
    my $self    = shift;
    my $type    = $self->stash('thing');    # event | entity
    my $id      = $self->stash('id');       # int id of the type
    my $depth   = $self->stash('depth')//0;    # number of nodes to traverse

    my @links   = ();       # ... array of links
    my %seen    = ();       # ... deduplication hash
    my $target  = { type => $type, id => $id };

    $self->build_graph(\@links, \%seen, $target, $depth);
    $self->render(json => \@links);
}

sub build_graph {
    my $self        = shift;
    my $link_aref   = shift;
    my $seen_href   = shift;
    my $target      = shift; # ... { type => $type, id => $id }
    my $depth       = shift;

    $depth --;

    return if ( $depth < 0 );   # done recursing

    my $type    = $target->{type};
    my $id      = $target->{id};
    my $skey    = $type.$id;

    if ( $type eq "event" ) {
        foreach my $entity_id ( $self->get_entities($target) ) {
            my $dkey = "entity".$entity_id;
            if ( ! defined  $seen_href->{seen}->{$skey.$dkey} ) {
                push @{$link_aref}, { event => $id, entity => $entity_id };
                $seen_href->{seen}->{$skey.$dkey}++;
                $seen_href->{count}->{$dkey}++;
            }
            my $target  = { type => "entity", id => $entity_id };
            $self->build_graph($link_aref, $seen_href, $target, $depth);
        }
    }
    else {
        foreach my $event_id ( $self->get_events($target) ) {
            my $dkey = "event".$event_id;
            if ( ! defined $seen_href->{seen}->{$skey.$dkey} ) {
                push @{$link_aref}, { event => $event_id, entity => $id };
                $seen_href->{seen}->{$skey.$dkey}++;
                $seen_href->{count}->{$dkey}++;
            }
            my $target = { type => "event", id => $event_id };
            $self->build_graph($link_aref, $seen_href, $target, $depth);
        }
    }
}

sub get_entities {
    my $self    = shift;
    my $target  = shift;
    my $type    = $target->{type};
    my $id      = $target->{id};

    my $col  = $self->env->mongo->collection('Event');
    my $cur  = $col->get_subthing($type, $id, "entity");
    my @ids  = map { $_->{id} } $cur->all; # mongo returns ->all as array of hashes not objs
    my @uids = uniq(@ids);
    
    return wantarray ? @uids : \@uids;
}

sub get_events {
    my $self    = shift;
    my $target  = shift;
    my $type    = $target->{type};
    my $id      = $target->{id};
    my $col  = $self->env->mongo->collection('Entity');
    my $cur  = $col->get_subthing($type, $id, "event");
    my @ids  = map { $_->{id} } $cur->all; # mongo returns ->all as array of hashes not objs
    my @uids = uniq(@ids);
    
    return wantarray ? @uids : \@uids;

}

1;
