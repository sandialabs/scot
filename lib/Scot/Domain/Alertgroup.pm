package Scot::Domain::Alertgroup;

use Data::Dumper;
use experimental 'signatures';
use strict;
use warnings;
use Storable qw(dclone);
use Moose;

extends 'Scot::Domain';

has max_alerts_per_alergroup => (
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

sub create_from_post ($self, $request) {
    my $log     = $self->log;
    my @results = ();

    $log->trace(__PACKAGE__." create : ",{filter=>\&Dumper, value => $request});

    my @alertgroups = $self->validate_alertgroup_request($request);

    foreach my $ag_request (@alertgroups) {
        push @results, $self->create_alertgroup($ag_request);
    }

    my $render_result   = $self->process_create_results(\@results);
    return $render_result;
}

=item <process_create_results($result_href)>

Take the results from create_alertgroup($ag_request_href) and 
format them into an href that is sent to the client

=cut

sub process_create_results ($self, $results) {
    my $mongo       = $self->env->mongo;
    my $log         = $self->env->log;
    my $mq          = $self->env->mq;
    my $statcol     = $mongo->collection('Stat');
    my $renderdata  = {
        thing   => 'alertgroup',
        action  => 'post',
    };

    my $error_count = 0;

    foreach my $res (@$results) {
        if ( defined $res->{error} ) {
            $error_count++;
            push @{$renderdata->{errors}}, $res->{error};
            next;
        }
        push @{$renderdata->{id}}, $res->{alertgroup};
        push @{$renderdata->{alerts}}, @{$res->{alerts}};
    }
    if ( $error_count == 0 ) {
        $renderdata->{status} = 'ok';
    }
    elsif ( $error_count eq scalar(@$results) ) {
        $renderdata->{status} = 'failed';
    }
    else {
        $renderdata->{status} = 'partial_success';
    }
    return $renderdata;
}

sub create_alertgroup ($self, $ag_request) {
    my $mongo       = $self->mongo;
    my $log         = $self->log;
    my $mq          = $self->env->mq;
    my @results     = ();
    my $agcol       = $mongo->collection('Alertgroup');
    my $alertcol    = $mongo->collection('Alert');
    my $alertscreated   = 0;

    if ( ! defined $ag_request->{owner} ) {
        $ag_request->{owner} = 'unknown';
    }

    my $alertgroup  = $agcol->create($ag_request);
    if ( ! defined $alertgroup ) {
        $log->error("Failed to create alertgoup with data: ",
                    { filter => \&Dumper, value => $ag_request });
        return { error => 'Failed to create Alertgroup' };
    }

    my $agid    = $alertgroup->id;
    my $data    = $alertgroup->data;
    my $result  = {
        alertgroup  => $agid,
    };

    foreach my $datum (@$data) {

        my $alert   = $alertcol->create({
            data        => $datum,
            subject     => $alertgroup->subject,
            alertgroup  => $agid,
            columns     => $alertgroup->columns,
            owner       => $alertgroup->owner,
            groups      => $alertgroup->groups,
            status      => 'open',
        });
        if ( defined $alert ) {
            $alertscreated++;
        }
        push @{$result->{alerts}}, $alert->id;
    }

    $alertgroup->update({
        '$set'  => {
            open_count      => $alertscreated,
            closed_count    => 0,
            promoted_count  => 0,
            alert_count     => $alertscreated,
        }
    });
    $result->{stats} = [
        'alertgroup created' => 1,
        'alert created'      => $alertscreated,
    ];
    $result->{mq_message}   = [{
        queues  => ["/topic/scot", "/queue/flair" ],
        message => {
            action  => 'updated',
            data    => {
                who     => $ag_request->{user},
                type    => 'alertgroup',
                id      => $agid,
            },
        }
    }];

    return $result;
}

sub list  ($self, $request){
    my $log     = $self->log;
    my $results = [];
    my $totalrecs   = 0;

    my ($query, $options)   = $self->build_mongo_query($request);
    
    $query->{'data.groups.read'} = { '$in' => $request->{groups} };

    ($results, $totalrecs)  = $self->list_alertgroups($request, $query, $options);
    my $render_result       = $self->process_list_results($results, $totalrecs);
    return $render_result;
}


sub list_alertgroups ($self, $request, $query, $options) {
    my $mongo   = $self->mongo;
    my $log     = $self->log;
    my $col     = $mongo->collection('Alertgroup');

    $log->trace("Listing Alertgroups with ", 
                {filter=>\&Dumper, value => [ $query, $options ] });

    my $count   = $col->count($query);
    my $cursor  = $col->find($query, $options);
    my @results = ();

    while ( my $alertgroup = $cursor->next ) {
        push @results, $alertgroup->as_hash;
    }
    return \@results, $count;
}

sub process_list_results ($self, $results,$totalrecs) {
    my $render_result   = {
        records             => $results,
        queryRecordCount    => scalar(@$results),
        totalRecordCount    => $totalrecs,
    };
    return $render_result;
}

sub get_one  ($self, $request){
    my $log     = $self->log;
    my $mongo   = $self->mongo;
    my $id      = $request->{id} + 0;
    my $col     = $mongo->collection('Alertgroup');
    my $obj     = $col->find_iid($id);
    my $rendered    = $self->render_get_one($request, $obj);
    return $rendered;
}

sub render_get_one ($self, $request, $obj) {
    if (! defined $obj) {
        die "Object not found";
    }
    if ( $obj->is_permitted('read', $request->{groups}) ) {
        return $obj->as_hash;
    }
    die "User does not have permission";
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
    my $mq      = $self-

sub update_alertgroup ($self, $request) {
    my $log     = $self->log;
    my $mongo   = $self->mongo;
    my $id      = $request->{id} + 0;
    my $col     = $mongo->collection('Alertgroup');
    my $obj     = $col->find_iid($id);
    my @results = ();

    if ( ! $obj->is_permitted("modify", $request->{groups}) ) {
        die "User does not have permission";
    }

    push @results, @{$self->validate_request($request)};
    my $update    = $request->{data}->{json};
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

sub validate_request ($self, $request) {
    my @disallowed  = (qw(body body_plain body_flair view_history));
    my @results     = ();
    if ( grep { defined $request->{data}->{json}->{$_} } @disallowed ) {
        push @results, { warn => 'attempted updated to protected field' };
        delete $request->{data}->{json}->{$_};
    }
    return wantarray ? @results : \@results;
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

=pod

Sometimes alertgroups have many hundreds of rows.  This function will
split those mega alertgroups into multiple smaller alertgroups.

=cut

sub validate_alertgroup_request ($self, $request){
    my $log         = $self->log;
    my @ag_request  = ();

    $log->trace("validate_alertgroup_request");

    my $json        = $request->{data}->{json};
    my $alertdata   = delete $json->{data}; # remove row data 
    my $subject     = $json->{subject};
    my $rowcount    = scalar(@$alertdata);
    my $rowlimit    = $self->max_alerts_per_alertgroup;
    my $items       = int($rowcount/$rowlimit);
    $items++ if ( $rowcount % $rowlimit != 0 );
    my $item        = 1;

    $log->trace("  $rowcount rows of alert data in alertgroup");
    $log->trace("  Generating $items alertgroups");

    while (my @subalerts = splice(@$alertdata, 0, $rowlimit) ) {
        $subject .= " (part $item of $items)" if ( $items > 1 );
        my $clone = dclone($json);
        $clone->{subject} = $subject;
        $self->validate_permissions($clone);
        $self->ensure_message_id($clone);
        $self->build_columns($clone);
        push @{$clone->{data}}, @subalerts;
        push @ag_request, $clone;
        $item++;
    }
    return wantarray ? @ag_request : \@ag_request;
}

sub validate_permissions ($self, $aghref) {
    my $log     = $self->log;
    
    if (! defined $aghref->{groups}->{read} ) {
        $aghref->{groups}->{read} = $self->default_alergroup_read_groups;
    }
    if (! defined $aghref->{groups}->{modify} ) {
        $aghref->{groups}->{modify} = $self->default_alertgroup_modify_groups;
    }
    
    # ensure submitted groups are all lowercase
    foreach my $t (qw(read modify)) {
        $aghref->{groups}->{$t} = [ map { lc($_) } @{$aghref->{groups}->{$t}} ];
    }
}

1;
