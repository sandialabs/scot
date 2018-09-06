package Scot::Role::Views;
use Moose::Role;
use namespace::autoclean;


=head1 Name

Scot::Role::Alerts

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<views>

The number of times the consuming model has been viewed

=cut


has views  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

=item B<view_history>

History of the first view history by user.

    {
        username    => {
            when    => epoch_time,
            where   => string_representation_of_ipaddress,
        }
    }

=cut

has view_history => (
    is          => 'ro',
    isa         => 'HashRef',
    traits      => ['Hash'],
    required    => 1,
    default     => sub {{}},
);

=back

=head1 Methods

=over 4

=item B<add_view($user, $ipaddr, $when)>

increments the B<views> attribute and sets view_history for $user

=cut

sub add_view {
    my $self    = shift;
    my $user    = shift;
    my $ipaddr  = shift;
    my $when    = shift;

    unless ($user) {
        $user   = "unknown";
    }
    unless ($when) {
        $when   = time();
    }
    unless ($ipaddr) {
        $ipaddr = "unknown";
    }

    $self->update({
        '$inc'  => { views => 1 },
        '$set'  => {
            "view_history.$user" =>  { when => $when, where => $ipaddr }
        },
    });

# this could be used to update response time as we go, but not sure 
# if this is the right way.
#    if ( $self->views == 1 ) {
#        # first view, return the elapsed time since creation
#        return $when - $self->created;
#    }
#    return undef;
}

=back

=cut

1;

