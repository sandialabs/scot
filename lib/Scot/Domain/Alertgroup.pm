package Scot::Domain::Alertgroup;

use strict;
use warnings;
use Moose;
use experimental 'signatures';
no warnings qw(experimental::signatures);
use Storable qw(dclone);
use Data::Dumper;
use lib '../../../lib';
use Scot::Domain::Alert;

extends 'Scot::Domain';

sub _build_collection ($self) {
    return $self->mongo->collection('Alertgroup');
}

has max_alerts_per_alertgroup => (
    is      => 'ro',
    isa     => 'Int',
    required=> 1,
    default => 100,
);

has datefields  => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [ qw(created updated) ] },
);

has numfields   => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [ qw(id views alert_count) ] },
);



sub create ($self, $request) {
    if ( ! $request->is_valid_create_request ) {
        die "Invalid Create Request Data";
    }
    my $create_href = $request->get_create_href;
    my $subject     = delete $create_href->{subject};

    my $data        = $request->json->{data};
    my $alert_count = scalar(@$data);
    my $limit       = $self->max_alerts_per_alertgroup;
    my $parts       = int($alert_count/$limit);
    my $remainder   = $alert_count % $limit;
    $parts++ if ($remainder != 0);
    my $page        = 1;
    my $agcol       = $self->collection;
    my @results;

    $self->log->debug("create_href => ", {filter=>\&Dumper, value => $create_href});

    while ( my @subset = splice(@$data, 0, $limit) ) {

        $create_href->{subject} = ($parts > 1) ? 
            "$subject (part $page of $parts)" :
            $subject;

        $create_href->{alert_count}     = scalar(@subset);
        $create_href->{open_count}      = scalar(@subset);
        $create_href->{closed_count}    = 0;
        $create_href->{promoted_count}  = 0;

        my $alertgroup = $agcol->create($create_href);
        my @ts         = $self->tag_source_bookkeep($alertgroup);
        my $alertdom   = $self->get_related_domain('alert');
        my $alert_ids  = $alertdom->create_linked($alertgroup, \@subset);

        push @results, { 
            alertgroup  => $alertgroup->id,
            alerts      => $alert_ids,
        };
    }
    return wantarray ? @results : \@results;
}

sub process_create_result ($self, $result, $request) {
    # 1. send notifications
    foreach my $agresult (@$result) {
        $self->amq_send_create(
            'alertgroup', $agresult->{alertgroup}, $request->user
        );
    }
    # 2. build return
    my $return  = {
        code    => 202,
        json    => $result,
    };
    return $return;
}


sub list  ($self, $request){
    my $log     = $self->log;
    my $results = [];
    my $totalrecs   = 0;

    my ($query, $options)   = $self->build_mongo_query($request);
    
    $query->{'groups.read'} = { '$in' => $request->{groups} };

    $results  = $self->list_alertgroups($request, $query, $options);
    return $results;

}


sub list_alertgroups ($self, $request, $query, $options) {
    my $mongo   = $self->mongo;
    my $log     = $self->log;
    my $col     = $self->collection;

    my $count   = $col->count($query);
    my $cursor  = $col->find($query, $options);
    my @results = ();

    while ( my $alertgroup = $cursor->next ) {
        my $href    = $alertgroup->as_hash;
        push @results, $href;
    }
    return {
        rows    => \@results, 
        count   => $count
    };
}

sub process_list_results ($self, $result, $request) {
    my $return   = {
        code    => 200,
        json    => {
            records             => $result->{rows},
            queryRecordCount    => scalar(@{$result->{rows}}),
            totalRecordCount    => $result->{count},
        }
    };
    return $return;
}

sub get_one  ($self, $request){
    my $id          = $request->{id} + 0;
    my $col         = $self->collection;
    my $obj         = $col->find_iid($id);
    $self->update_views($obj, $request);
    return $obj;

}

sub update_views ($self, $obj, $request) {
    $obj->add_view($request->user, $request->ipaddr);
}

sub process_get_one ($self, $request, $obj) {
    if (! defined $obj) {
        return {
            code    => 404,
            error   => "object not found",
        };
    }
    if ( $obj->is_permitted('read', $request->{groups}) ) {
        my $href    = $obj->as_hash;
        return {
            code    => 200,
            json    => $href,
        };
    }
    return {
        code    => 403,
        error   => "User does not have permission",
    };
}

sub update  ($self, $request){
    my $log     = $self->log;
    my $mongo   = $self->mongo;
    my $id      = $request->{id} + 0;
    my @results = $self->update_alertgroup($request);
    $self->send_update_notices($id);
    my $render_results  = $self->process_update_results(\@results);
    return $render_results;
}

sub send_update_notices ($self, $agid) {
    my $mq      = $self->env->mq;
}

sub update_alertgroup ($self, $request) {
    my $log     = $self->log;
    my $mongo   = $self->mongo;
    my $id      = $request->id + 0;
    my $col     = $self->collection;
    my $obj     = $col->find_iid($id);
    my @results = ();

    if ( ! $obj->is_permitted("modify", $request->{groups}) ) {
        die "User does not have permission";
    }

    my $update    = $request->get_update_href();
    try {
        $obj->update({ '$set' => $update});
        push @results, { updated => $id };
    }
    catch {
        $log->error("Error updating Alertgroup $id: $_");
        push @results, { error => "failed to update Alertgroup $id: $_" };
    };
    return wantarray ? @results : \@results;
}

sub get_related ($self, $request) {
    my $relname  = $request->{subcollection};
    my $id       = $request->{id};
    my $reldom   = $self->get_related_domain($relname);

    if ( ! defined $reldom ) {
        return {error => "unsupported related item type $relname"};
    }
    return $reldom->find_related($request, 'alertgroup', $id);
}

sub process_get_related ($self, $result) {
    return {
        code    => 200,
        json    => $result,
    };
}

sub delete  ($self, $request){

}

sub undelete  ($self, $request){

}

sub promote  ($self, $request){

}

sub unpromote  ($self, $request){

}

sub link  ($self, $request){

}

1;
