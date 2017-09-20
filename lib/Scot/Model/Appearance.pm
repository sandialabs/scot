package Scot::Model::Appearance;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Appearance

=head1 Description

The model of a Appearance Record

allows the tracking of Appearable items like 
tag, source, and entity

basically a timestamp of everytime it occurrs in the database

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
    Scot::Role::Target
    Scot::Role::Value
);

=head1 Attributes

=over 4

=item B<type>

the type of the appearance record: tag, source, or entity

=cut

has type    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<value>

Moved to Role

the string of the tag, source or entity being tracked


has value   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=cut

=item B<apid>

The id of the tag, source or entity in its respective collection

=cut

has apid => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
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

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
