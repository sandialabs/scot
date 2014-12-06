package Scot::Roles::Subjectable;

use Moose::Role;
use Data::Dumper;
use namespace::autoclean;

# requires 'log';

=item C<subject>

    string describing the subject of the object

=cut 

has subject => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);


1;

