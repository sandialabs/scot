package Scot::Model::Entity;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Entity

=head1 Description

The model of an individual Entity

Entities are linked to other items via
the Link collection

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Entriable
    Scot::Role::Hashable
    Scot::Role::Sharable
    Scot::Role::Value
);

=head1 Attributes

=over 4

=item B<value>

Moved to Role

the string that is the entity


has value  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '',
);

=cut

=item B<type>

the type of entity

=cut

has type  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '',
);

=item B<match_type>

regex|explicit
regex is things found by Regex 
explicit are user entered strings (via highlighting 
or otherwise creating an entity.  The extractor will
pull all entities marked as explicit and do exact
string matching to find.

=cut

has match_type => (
    is      => 'ro',
    isa     => 'Str',
    required    => 1,
    default     => 'regex',
);

=item B<classes>

Array of css classes to flair this entity with

=cut

has classes => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    required    => 1,
    default => sub {[]},
);

=item B<status>

some entities are very noisey and you probably will want to 
avoid tracking them, for example your top level domain name
valid statuses = tracked | untracked

=cut

has status  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'tracked',
);

=item B<data>

hold data in a key value store about the entity.
for an example:
    you can store the binary form of Ip addr for better matching
    data.binip = 11101101101010110110...

This data structure will expand with enrichment 

=cut

has data    => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => [ 'Hash' ],
    required    => 1,
    default => sub {{}},
);

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
