package Scot::Role::TLP;
use Moose::Role;

=head1 Name

Scot::Role::Alerts

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<tlp>

the Traffic Light Protocol "color"

    unset   = the absense of a TLP marking
    white   = Unlimited Release
    green   = sector wide release
    amber   = distro limited to local parties/trusted partners
    red     = do not share without permission from author
    black   = do not share and "you didn't hear this from me"

=cut

has tlp    => (
    is          => 'ro',
    isa         => 'TLP_color',
    required    => 1,
    default     => 'unset',
);

sub tlp_permits_sharing {
    my $self    = shift;
    
    if ( $self->tlp eq "black" ) {
        return undef;
    }
    return 1;
}

=back

=cut

1;
