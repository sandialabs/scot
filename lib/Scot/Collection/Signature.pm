package Scot::Collection::Signature;
use lib '../../../lib';
use Moose 2;

extends 'Scot::Collection';
    
=head1 Name

Scot::Collection::Signature

=head1 Description

Custom collection operations on signatures

=head1 Methods

=over 4

=item B<create_from_api>

Create Signature from POST to API

=cut

sub create_from_api {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("Creating Signature from POST to API");

    my $user        = $request->{user};
    my $json        = $request->{request}->{json};
    $json->{owner}  = $user;
    my @tags        = $env->get_req_array($json, "tags");
    my @sources     = $env->get_req_array($json, "sources");
    
    my $signature   = $self->create($json);

    unless ( $signature ) {
        $log->error("Error creating Signature from ",
                    { filter => \&Dumper, value => $request });
        return undef;
    }

    my $id  = $signature->id;

    if ( scalar(@sources) > 0 ) {
        my $col = $env->mongo->collection('Source');
        $col->add_source_to("signature", $id, \@sources);
    }
    if ( scalar(@tags) > 0 ) {
        my $col = $env->mongo->collection('Tag');
        $col->add_source_to("signature", $id, \@tags);
    }

    return $signature;
}

1;
