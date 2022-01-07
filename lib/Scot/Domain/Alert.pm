package Scot::Domain::Alert;

use strict;
use warnings;
use Moose;
use experimental qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;

extends 'Scot::Domain';

sub _build_collection ($self) {
    return $self->mongo->collection('Alert');
}

# to create an alert, you must provide an alertgroup
# to attach the alert to.
sub create ($self, $request) {
}

sub create_linked ($self, $alertgroup, $alerts) {
    my @alert_ids  = ();

    foreach my $alert (@$alerts) {
        my $row = {
            subject     => $alertgroup->subject,
            alertgroup  => $alertgroup->id,
            status      => 'open',
            columns     => $alertgroup->columns,
            data        => $alert,
        };
        $self->log->debug("creating alert: ",{filter => \&Dumper, value => $row});
        my $alert = $self->mongo->collection('Alert')->create($row);
        $self->log->debug("created alert ".$alert->id);
        push @alert_ids, $alert->id;
    }
}

sub find_related ($self, $request, $type, $id) {
    # type is the source we are trying to find alerts related to
    # id is the id of the source.
    my $return = {};
    # find all alerts related to alertgroup:$id
    if ( $type eq 'alertgroup' ) {
        my $query   = { alertgroup => $id };
        my $count   = $self->collection->count($query);
        my $cursor  = $self->collection->find($query);
        my @result  = ();
        while ( my $ag = $cursor->next ) {
            my $href    = $ag->as_hash;
            push @result, $href;
        }
        $return = {
            totalRecordCount    => $count,
            queryRecordCount    => scalar(@result),
            records             => \@result,
        };
    }
    # find all alerts linked to an entity
    if ( $type eq 'entity' ) {
        my $target = { id => $id, type => 'entity' };
        return $self->get_related_domain('link')->find_linked_by_type('alert', $target);
    }
    # find all alerts promoted to an event
    if ( $type eq 'event' ) {
        return $self->collection->find({promotion_id    => $id});
    }
    return $return;
}

sub update ($self, $request) {
    my $id  = $request->id + 0;
    my $obj = $self->collection->find_iid($id);
    
    if ( ! defined $obj ) {
        return { error => "alert $id not found" };
    }
    if ( ! $obj->is_permitted("modify", $request->{groups}) ) {
        return { error => "insufficent priviledge to modify" };
    }

    my $update  = $request->get_update_href();
    $self->log->debug("alert update is ",{filter=>\&Dumper, value => $update});
    my $result  = try {
        $obj->update({'$set' => $update});
        return { updated => $id };
    }
    catch {
        return { error => "failed updated of alert $id: $_" };
    };
    return $result;
}

sub get_related ($self, $request) {
    my $relname = $request->{subcollection};
    my $id      = $request->{id};
    my $reldom  = $self->get_related_domain($relname);

    if ( ! defined $reldom ) {
        return { error => "unsupported related ite type $relname"};
    }
    return $reldom->find_related($request, 'alert', $id);
}

1;
