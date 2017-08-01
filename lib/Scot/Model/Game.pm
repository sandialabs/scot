package Scot::Model::Game;

=head1 Name

Scot::Model::Game

=head1 Description

This model holds information about SCOT the GAME! 

=cut

use Moose;
use namespace::autoclean;

extends "Scot::Model";
with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
);

=head1 Attributes

=over 4

=cut

has game_name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has tooltip => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has lastupdate  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
);

=item B<results>

results are (
    { "_id": "username", total: x },
)

=cut

has results => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
);

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
