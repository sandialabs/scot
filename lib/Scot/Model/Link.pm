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

 item <---> target   unidirectional graph component

We are not restricting to single links, in other works

entity 123 <---> entry  1010 @ 1453132180
entity 123 <---> entry  1010 @ 1453132180
entity 123 <---> alert  1011001 @ 1453102111

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

=item B<pair>

this is the pair of items that are linked
[ { id: 1, type: "alert" }, {id:2, type:"alertgroup"} ]

=cut

has pair    => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [] },
);


__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
