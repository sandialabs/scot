package Scot::Roles::Sourceable;

use Moose::Role;
# use Data::Dumper;
use namespace::autoclean;

# requires 'log';

=item C<source>

 string that describe the the source or sources of the alert

=cut

has sources     => (
    is          =>  'rw',
    isa         =>  'ArrayRef',
    traits      => [ 'Array' ],
    required    =>  1,
    builder     => '_empty_sources',
    handles     => {
        add_source     => 'push',
        find_source    => 'first_index',
        grep_source    => 'grep',
        delete_source  => 'delete',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

sub _empty_sources {
    return [];
}

sub remove_source {
    my $self    = shift;
    my $mongo   = shift;
    my $source  = shift;
    my $log     = $self->log;

    if ( ! defined $mongo or ref($mongo) ne "Scot::Util::Mongo") {
        $log->error("2nd param to remove_source needs to be a Scot::Util::Mongo");
        return undef;
    }

    if ( ! defined $source or $source eq '' ) {
        $log->error("3rd param is the source and must be defined and not blank");
        return undef;
    }

    (my $type    = ref($self)) =~ s/Scot::Model::(.*)/$1/;
    $type       = lc($type);
    my $idfield = $self->idfield;
    my $id      = $self->$idfield;
    
    $log->debug("Removing Source $source from $type $id");

    my $index   = $self->find_source( sub {/$source/i} );
    if ( $index > -1 ) {
        $self->delete_source($index);
    }
    else {
        $log->error("Tag index of -1 returned.  Already gone?");
    }
}

sub add_to_sources {
    my $self    = shift;
    my $mongo   = shift;
    my $source  = shift;
    my $log     = $self->log;

    if ( ! defined $mongo or ref($mongo) ne "Scot::Util::Mongo" ) {
        $log->error("Second param to add_source needs to be Scot::Util::Mongo");
        return undef;
    }
    if ( ! defined $source or $source eq '') {
        $log->error("3rd param is the source and must be defined and not blank");
        return undef;
    }

    my @alreadysourced  = $self->grep_source( sub { /$source/i } );

    unless ( scalar(@alreadysourced) > 0 ) {
        $self->add_source($source);
        my $source_aref = $self->sources;
        @$source_aref   = sort @$source_aref;
        $self->sources($source_aref);
# don't think that this is necessary since this is called in build modification
# command, which is expected to update the disk document in the mongodb
#         $mongo->update_document($self);
    }

}

1;
