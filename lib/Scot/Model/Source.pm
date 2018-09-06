package Scot::Model::Source;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Source

=head1 Description

The model of an source record
Sources are linked through the
Link collection

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Value
);

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Value

=head1 Attributes

=over 4

=item B<value>

Moved to Scot::Role::Value

the name of the source

=cut

=item B<notes>

store a bried description or other information
about this source

=cut

has notes => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default    => 'none',
);


__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
