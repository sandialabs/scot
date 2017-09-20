package Scot::Model::Link;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Link

=head1 Description

The model of a Link Record

SCOT will allow you to associate just about anything with anything else.
A link is an "edge" in a graph sense.  Common "verticies" could include
"alerts", "entities", "events", etc.


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

=cut

has when  => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => sub { time(); },
);

=item B<vertices>

Array of Hashref of structure: 
{ 
  type      => collection_name, 
  id        => int_id,
} 

=cut

has vertices   => (
    is          => 'ro',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    required    => 1,
    default     => sub {[]},
);

=item B<weight>

A numerical score on the link.  In case you want one.

=cut

has weight   => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
    default     => 1,
);

=item B<context>

brief explanation for why your are linking

=cut

has context => (
    is      => 'ro',
    isa     => 'Str',
    required => 1,
    default => ' ',
);

=item B<memo>

array that matches vertices, but contains
mnemoic information about each vertex

[ 'memo string for v0', 'memo string for v1' ]

=cut

has memo => (
    is          => 'ro',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    required    => 1,
    default     => sub {[]},
);


__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
