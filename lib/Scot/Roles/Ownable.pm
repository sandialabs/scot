package Scot::Roles::Ownable;

use Moose::Role;
use Data::Dumper;
use namespace::autoclean;

=item C<owner>

 string representation of the username that owns this thing

=cut

has owner  => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);



1;

