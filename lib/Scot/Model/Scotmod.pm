package Scot::Model::Scotmod;

=head1 Name

Scot::Model::Scotmod

=head1 Description

This model describes the documents within the module collection.
A module cotains info about optional modules that should be loaded into 
the SCOT Env.pm module

=cut

use Moose;
use namespace::autoclean;

extends "Scot::Model";

with    qw(
    Meerkat::Role::Document
);

=head1 Attributes

=over 4

=item B<module>

The perl heirarchy name for the class to load.  e.g. Scot::Util::Foo

=cut

has module   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<attribute>

the name of the attribute to create that will hold the reference to the 
class that has been instantiated.

=cut

has attribute   => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
);

__PACKAGE__->meta->make_immutable();

1;
__END__

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
