package Scot::Role::Views;

use Moose::Role;
use namespace::autoclean;

=item B<views>

The number of times the consuming model has been viewed

=cut


has views  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

# array of { who => $a, when => $b, where => $c }

has view_history => (
    is          => 'ro',
    isa         => 'HashRef',
    traits      => ['Hash'],
    required    => 1,
    default     => sub {{}},
);

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
        $ipaddr = "unknonw";
    }

    $self->update({
        '$inc'  => { views => 1 },
        '$set'  => {
            "view_history.$user" =>  { when => $when, where => $ipaddr }
        },
    });
}


1;

