package Scot::Model::Link;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Link

=head1 Description

The model of a Link Record

Adding {target,id} to an array in Entity.pm is a performance killer
So Link records will link an Entity to a thing that contains it's entity

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
    Scot::Role::Target
);

=head1 Attributes

=over 4

=item B<when>

when it linked
allows us to keep track of timeseries like views of tags/entities etc.

=cut

has when  => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => sub { time(); },
);

=item B<entity_id>

the id of the entity

=cut

has entity_id   => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
);

=item B<value>

a copy of the entity value, makes some queries easier

=cut

has value   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<target>

from role Target.pm
what the entity is linked to

=cut


__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
