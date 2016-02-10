package Scot::Collection::Incident;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

=head1 Name

Scot::Collection::File

=head1 Description

Custom collection operations for Files

=head1 Methods

=over 4

=item B<create_from_api($handler_ref)>

Create an event and from a POST to the handler

=cut


sub create_from_api {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    $log->trace("Custom create in Scot::Collection::Incident");

    my $user    = $request->{user};
    my $json    = $request->{request}->{json};

    my @tags    = $env->get_req_array($json, "tags");

    my $incident    = $self->create($json);

    unless ($incident) {
        $log->error("ERROR creating Incident from ",
                    { filter => \&Dumper, value => $request});
        return undef;
    }

    my $id  = $incident->id;

    if ( scalar(@tags) > 0 ) {
        $self->upssert_links("Tag", "incident", $id, @tags);
    }
    return $incident;
}

sub create_promotion {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;

    my $reportable      = $self->get_value_from_request($req, "reportable");
    my $subject         = $object->subject // 
                            $self->get_value_from_request($req, "subject");
    my $href    = {
        reportable  => $reportable ? 1 : 0,
        subject     => $subject,
    };
    my $category        = $self->get_value_from_request($req, "category");
    $href->{category}   = $category if (defined($category));
    my $sensitivity     = $self->get_value_from_request($req, "sensitivity");
    $href->{sensitivity} = $sensitivity if (defined $sensitivity);
    my $occurred        = $self->get_value_from_request($req, "occurred");
    $href->{occurred}   = $occurred if (defined $occurred);
    my $discovered      = $self->get_value_from_request($req, "discovered");
    $href->{discovered} = $occurred if (defined $discovered);

    my $incident = $self->create($href);
    return $incident;
}

1;
