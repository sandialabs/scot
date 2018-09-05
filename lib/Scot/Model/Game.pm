package Scot::Model::Game;

=head1 Name

Scot::Model::Game

=head1 Description

This model holds information about SCOT the GAME! 

=head1 Extends 

Scot::Model

=cut

use Moose;
use namespace::autoclean;

extends "Scot::Model";
with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
);

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Hashable

=head1 Attributes

=over 4

=item B<game_name>

The name of the game

=cut

has game_name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<tooltip>

what to display as a tooltip

=cut

has tooltip => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<lastupdate>

The seconds since unix epoch when this record was updated

=cut

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
