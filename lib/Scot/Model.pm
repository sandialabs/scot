package Scot::Model;

=head1 Name

Scot::Model

=head1 Description

The Base class for Scot Model's

=cut

use lib '../../lib';

use utf8;
use v5.18;
# use Encode;
use Scot::Types;
use Scot::Env;
use Moose;
# use MooseX::Storage;
use namespace::autoclean;

=head1 Attributes

=over 4

=item B<env>
not used?
Link to the Scot::Env singleton


has env =>  (
    is      => 'ro',
    isa     => 'Scot::Env',
    required    => 1,
    traits => [ 'DoNotSerialize' ],
    default => sub { Scot::Env->instance; },
);

=cut

=item B<_id>

Every Mongo Document has one

=cut

has '_id'   => (
    is          => 'ro',
    isa         => 'MongoDB::OID',
    writer      => 'set_mongo_oid',
    predicate   => 'mongo_oid_set',
    clearer     => 'reset_oid',
);

=item B<id>

the integer id for the model instance
Integer id's are for human readability of the api 

=cut

has id => (
    is          => 'ro',
    isa         => 'IID',
    required    => 1,
);

=item B<location>

the location string that identifies this scot instance

=cut

has location    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'local',
);

=back

=head1 Methods

=over 4

=item B<get_collection_name()>

submit an object get the lowercased collection name.  For example:

    my $thing = Scot::Model::Alertgroup->new();
    say $thing->get_collection_name();

    alertgroup

=cut

=back

=cut

sub get_collection_name {
    my $self    = shift;
    my $thing   = lc((split(/::/, ref($self) ))[-1]);
    return $thing;
}

1;
