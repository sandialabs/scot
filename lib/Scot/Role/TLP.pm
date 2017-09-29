package Scot::Role::TLP;

use Moose::Role;


=item B<tlp>

the TLP "color"

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

1;
