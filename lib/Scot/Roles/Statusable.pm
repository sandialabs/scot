package Scot::Roles::Statusable;

use Moose::Role;
# use Data::Dumper;
use namespace::autoclean;

# requires 'log';

=item C<status>
 string that describe the status of the object
=cut
has status     => (
    is          =>  'rw',
    isa         =>  'valid_status',  # must set this in object
    required    =>  1,
    builder     => '_default_status',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);
sub _default_status {
    return "open";
}

1;
