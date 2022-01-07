package Scot::Domain::Entity;

use strict;
use warnings;
use Moose;
use experimental qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;

extends 'Scot::Domain';

sub _build_collection ($self) {
    return $self->mongo->collection('Entity');
}

# to create an alert, you must provide an alertgroup
# to attach the alert to.
sub create ($self, $request) {
}

sub find_related ($self, $request, $type, $id) {
    # type is the source we are trying to find entities related to
    # id is the id of the source.
    my $return = {};
    # find all entities related to alertgroup:$id
    if ( $type eq 'alertgroup' ) {
        my $target  = { type => 'alertgroup', id => $id };
        my $domain  = $self->get_related_domain('link');
        my @eids    = $domain->get_entity_id_set($target);
        my $query   = { id => { '$in' => \@eids } };
        return $self->get_result_set($request, $query, $target);
    }
    # find all entities linked to an alert
    if ( $type eq 'alert' ) {
        my $target = { id => $id, type => 'alert' };
        return $self->get_related_domain('link')->find_linked_by_type('entity', $target);
    }
    return $return;
}

sub get_result_set ($self, $request, $query, $target) {
    my %result  = ();
    my $count   = $self->collection->count($query);
    my $cursor  = $self->collection->find($query);
    while ( my $entity = $cursor->next ) {
        my $href    = $entity->as_hash;
        my $value   = delete $href->{value};
        my @entries = $self->get_related_domain('entry')->get_threaded($request, $target);
        $result{$value} = $href;
        $result{$value}{entry}  = scalar(@entries);
        $result{$value}{entries}= \@entries;
    }
    return {
            totalRecordCount    => $count,
            queryRecordCount    => scalar(keys %result),
            records             => \%result,
    };
}



1;
