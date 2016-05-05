package Scot::Collection::Intel;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

=head1 Name

Scot::Collection::Intel

=head1 Description

Custom collection operations for Intel

=head1 Methods

=over 4

=item B<create_from_handler($handler_ref)>

Create an event and from a POST to the handler

=cut


sub create_from_api {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Custom create in Scot::Collection::Intel");

    my $json    = $request->{request}->{json};
    my $user    = $request->{user};

    my @tags    = $env->get_req_array($json, "tags");
    my @sources = $env->get_req_array($json, "sources");

    unless ( $json->{readgroups} ) {
        $json->{groups}->{read}   = $env->default_groups->{read};
    }
    unless ( $json->{modifygroups} ) {
        $json->{groups}->{modify} = $env->default_groups->{modify};
    }

    my $intel   = $self->create($json);

    my $id  = $intel->id;

    if ( scalar(@sources) > 0 ) {
        my $col = $env->mongo->collection('Source');
        $col->add_source_to("intel", $intel->id, \@sources);
    }
    if ( scalar(@tags) > 0 ) {
        my $col = $env->mongo->collection('Tag');
        $col->add_source_to("intel", $intel->id, \@tags);
    }

    return $intel;

}


1;
