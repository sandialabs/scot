package Scot::Model::WorkerStat;

use lib '../../../lib';
use namespace::autoclean;
use Moose;

=head1 Name

Scot::Model::WorkerStat

=head1 Description

Store ephemeral status of a worker so API can display

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Times
);

=head1 Consumed Roles

    Meerkat::Role::Document

=head1 Attributes

=over 4

=cut

has procid  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
);

has otype   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has oid     => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
);

has node    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has total_node_count    => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
);

has processed_count => (
    is          => 'ro',
    isa         => 'Int',
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
