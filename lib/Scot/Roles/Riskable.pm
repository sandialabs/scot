package Scot::Roles::Riskable;

use Moose::Role;
use namespace::autoclean;

=head1 Role Riskable

=item C<risk_ratings>
 this attribute is a hash reference of 
 the form: { $username => $score, ... }
 We care who is evaluating and what the rate the risk as.
 anything else?
=cut

has risk_ratings => (
    is          => 'rw',
    isa         => 'HashRef',
    traits      => [ 'Hash' ],
    required    => 1,
    builder     => '_build_empty_href',
    handles     => {
        set_risk_rating         => 'set',
        get_risk_rating         => 'get',
        get_risk_scores         => 'values',
        get_all_risk_ratings    => 'kv',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

sub _build_empty_href {
    return {};
}

=item C<risk> 
 the mean of the risk ratings
=cut

sub risk {
    my $self    = shift;
    my $sum     = 0;
    my $pop     = 0;

    foreach my $score (@{$self->get_risk_scores}) {
        $sum += $score;
        $pop++;
    }
    my $mean = $sum / $pop;
    return $mean;
}
1;
