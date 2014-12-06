package Scot::Roles::Whenable;

use Moose::Role;
use Data::Dumper;
use namespace::autoclean;

# requires 'log';

=item C<when>

integer number of seconds since the epoch "when" an object occurred,
the only user settable timestamp field, used for ordering timelines
defaults to the creation time of the object

=cut 

has when => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    builder     => '_timestamp',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
        alt_data_sub    => 'fmt_time',
    },
);


1;

