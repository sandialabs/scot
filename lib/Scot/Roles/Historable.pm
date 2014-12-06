package Scot::Roles::Historable;

use Moose::Role;
# use Data::Dumper;
use namespace::autoclean;

# requires 'log';

=item C<history>

 Array of hashrefs that describe the objects history

=cut

has history        => (
    is          =>  'rw',
    isa         =>  'ArrayRef[HashRef]',
    traits      =>  [ 'Array' ],
    builder     =>  '_build_history',
    handles     =>  {
        add_history =>  'push',
        all_history =>  'elements',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=item C<changes>

 number of changes made to object without write to backing store
 not used currently, but look for magic moose-y stuff in future
 to autoincrement any when any attribute is set.
 at that time this probably should be in the Model.pm 

=cut

has changes => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    required => 1,
    traits  => ['Counter'],
    handles => {
        inc_changes     => 'inc',
        reset_changes   => 'reset',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

sub _build_history {
    my $self    = shift;
    return [];
}

sub add_historical_record {
    my $self    = shift;
    my $recref  = shift;
    $self->add_history($recref);
}

1;
