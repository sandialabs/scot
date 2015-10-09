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
        $self->upssert_targetables("Tag", "incident", $id, @tags);
    }
    return $incident;
}


1;
