package Scot::Collection::Alertgroup;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';

with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

=head1 Name

Scot::Collection::Alertgroup

=head1 Description

Custom collection operations for Alertgroups

=head1 Methods

=over 4

=item B<create_from_api($request_href)>

Create an alertgroup and sub alerts from a POST to the handler

=cut

sub create_from_api {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    $log->trace("Create Alertgroup");

    # alertgroup creation will receive the following in the json portion of the request
    # request => {
    #    message_id  => '213123',
    #    subject     => 'subject',
    #    data       => [ { ... href structure ...      }, { ... } ... ],
    #    tags       => [],
    #    sources    => [],
    # }

    my $request = $href->{request}->{json};

    my $data    = $request->{data};
    delete $request->{data};

    my $tags    = $request->{tags};
    delete $request->{tags};

    my $alertgroup  = $self->create($request);

    unless ( defined $alertgroup ) {
        $log->error("Failed to create Alertgroup with data ",
                    { filter => \&Dumper, value => $request});
        return undef;
    }

    my $id          = $alertgroup->id;

    if ( defined $tags && scalar(@$tags) > 0 ) {
        foreach my $tag (@$tags) {
            my $tag = $mongo->collection('Tag')->add_tag_to("alertgroup",$id, $tag);
        }
    }

    $log->trace("Creating alerts belonging to Alertgroup ". $id);

    my $alert_count     = 0;
    my $open_count      = 0;
    my $closed_count    = 0;
    my $promoted_count  = 0;
    my %columns         = ();
            
    foreach my $alert_href (@$data) {

        my $chref   = {
            data        => $alert_href,
            alertgroup  => $id,
            status      => 'open',
        };

        my $alert = $mongo->collection("Alert")->create($chref);

        unless ( defined $alert ) {
            $log->error("Failed to create Alert from ",
                         { filter => \&Dumper, value => $chref });
            next;
        }

        # not sure we need a notification for every alert, maybe just alertgroup
        # alert triage may want this at some point though
        # $env->amq->send_amq_notification("creation", $alert);

        $alert_count++;
        $open_count++       if ( $alert->status eq "open" );
        $closed_count++     if ( $alert->status eq "closed" );
        $promoted_count++   if ( $alert->status eq "promoted");
    }

    $alertgroup->update({
        '$set'  => {
            open_count      => $open_count,
            closed_count    => $closed_count,
            promoted_count  => $promoted_count,
            alert_count     => $alert_count,
        }
    });
    $env->amq->send_amq_notification("creation", $alertgroup);
    return $alertgroup;
}

sub refresh_data {
    my $self    = shift;
    my $id      = shift;

    my $alertgroup  = $self->find_iid($id);

    my $cursor  = $self->meerkat->collection('Alert')->find({alertgroup => $id});

    my %count   = ();
    while ( my $alert = $cursor->next ) {
        $count{total}++;
        $count{$alert->status}++;
    }
    $alertgroup->update({
        '$set'  => {
            open_count      => $count{open} // 0,
            closed_count    => $count{closed} // 0,
            promoted_count  => $count{promoted} // 0,
            alert_count     => $count{total},
        }
    });
}




1;
