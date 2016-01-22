package Scot::Model::Link;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Link

=head1 Description

The model of a Link Record

Solves the problem of how to associate a group of things with
another group of things without resorting to arrays (previous attempt)
the $addToSet funtction is so slow.  

Think of this as a multi to multi junction table from SQL  world

or

 item ---> target   unidirectional graph component

We are not restricting to single links, in other works

entity 123 ---> entry  1010 @ 1453132180
entity 123 ---> entry  1010 @ 1453132180
entity 123 ---> alert  1011001 @ 1453102111

which gives us the count (3) and a timeseries of when we first saw entity 123
and the subsequent appearances.

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
);

=head1 Attributes

=over 4

=item B<item_type>

The item that we wish to associate with the target
usually something like an entity

=cut

has item_type  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'unknown',
);

=item B<item_id>

the id of the item being linked

=cut

has item_id  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

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

=item B<target_type>

the target of the link

=cut

has target_type    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '',
);

=item B<target_id>

the id of the item being targeted

=cut

has target_id  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
