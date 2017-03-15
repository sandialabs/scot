package Scot::Collection::Sigbody;
use lib '../../../lib';
use Moose 2;
use v5.18;
use Data::Dumper;

extends 'Scot::Collection';
    
=head1 Name

Scot::Collection::Sigbody

=head1 Description

Custom collection operations on sigbody

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

    $log->debug("Creating Sigbody from POST to API");
    $log->debug(Dumper($request));

    my $json        = $request->{request}->{json};

    $log->debug("json is ". Dumper($json));
    
    my $sigbody   = $self->create($json);

    unless ( $sigbody ) {
        $log->error("Error creating Sigbody from ",
                    { filter => \&Dumper, value => $request });
        return undef;
    }

    return $sigbody;
}


1;
