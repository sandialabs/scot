package Scot::Model::Domainstat;

use lib '../../../lib';
use Moose;
use DateTime;
use namespace::autoclean;

=head1 Name

Scot::Model::Stat

=head1 Description

The model of a Alerttype Stat

=cut

extends 'Scot::Model';

with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
    Scot::Role::Times
);

=head1 Attributes

=over 4

=item B<entity_id>

The domain entity's id

=cut

has entity_id  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

=item B<value>

The domain text 

=cut

has value    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'Domain-Unknown',
);

=item B<count>

The number of times the domain is linked

=cut

has count    => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

=item B<entries>

the number of entries linked to this entity

=cut

has entries     => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

=item B<blocklist> 

cache of the blocklist data

=cut

has blocklist    => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub {{}},
);



=back

=cut


__PACKAGE__->meta->make_immutable;

1;
