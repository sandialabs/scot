package Scot::Roles::Labelable;

use Moose::Role;
# use Data::Dumper;
use namespace::autoclean;

# requires 'log';

=item C<labels>
 Array ref of strings that ref machine generated labels 
=cut
has labels     => (
    is          =>  'rw',
    isa         =>  'ArrayRef[Str]',
    traits      =>  [ 'Array' ],
    required    =>  1,
    builder     => '_build_labels',
    handles     => {
        labels_count   => 'count',
        add_label      => 'push',
        pop_label      => 'pop',
        sorted_labels  => 'sort',
        all_labels     => 'elements',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

sub _build_labels {
    my $self    = shift;
    return [];
}
1;
