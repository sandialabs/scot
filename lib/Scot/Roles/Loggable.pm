package Scot::Roles::Loggable;

use Moose::Role;
use Data::Dumper;
use namespace::autoclean;

=item C<log>

 the local reference to the logger

=cut

has 'log'   => (
    is          => 'rw',
    isa         => 'Maybe[Object]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => { serializable    => 0, },
);

1;
