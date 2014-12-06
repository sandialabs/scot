package Scot::Roles::Targetable;

use Moose::Role;
use Data::Dumper;
use lib '../../';
use namespace::autoclean;

requires 'log';

=item C<target_type> 
 what is the file associated with event, alert, etc.
=cut
has target_type => (
    is          => 'rw',
    isa         => 'Str',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<target_id>
 the id of the target
=cut
has target_id => (
    is          => 'rw',
    isa         => 'Int',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

sub get_target_obj {
    my $self    = shift;
    my $mongo   = shift;
    my $log     = $self->log;

    unless (defined $mongo and ref($mongo) eq "Scot::Util::Mongo") {
        $log->error("Failed to provide Scot::Util::Mongo object");
        return undef;
    }

    my $collection  = $mongo->plurify_name($self->target_type);
    my $idfield     = $mongo->get_int_id_field_from_collection($collection);
    my $object = $mongo->read_one_document({
        collection  => $collection,
        match_ref   => { $idfield => $self->target_id }
    });
    return $object;
}


1;
