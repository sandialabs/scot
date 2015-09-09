package Scot::Role::Views;

use Moose::Role;
use namespace::autoclean;

=item B<views>

The number of times the consuming model has been viewed

=cut


has views  => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

sub increment_views {
    my $self    = shift;
    my $amount  = shift // 1;
    $self->update_inc( views => $amount );
}


1;

