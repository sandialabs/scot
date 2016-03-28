package Scot::Model::Entry;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Entry

=head1 Description

The model of an individual Entry

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Body
    Scot::Role::Entitiable
    Scot::Role::Hashable
    Scot::Role::Parsed
    Scot::Role::Permission
    Scot::Role::Target
    Scot::Role::Times
);

=head1 Attributes

=over 4

=item B<summary>

this bool if true says that this entry is the summary
and should be at the top.  If there are multiple summaries
then they are listed in chrono order

=cut

has summary     => (
    is          => 'ro',
    isa         => 'Bool',
    traits      => ['Bool'],
    required    => 1,
    default     => 0,
    handles     => {
        make_summary    => 'set',
        unsummarize     => 'unset',
    },
);

=item B<task>

the hash of {
    when    => seconds_epoch,
    who     => username,
    status  => open|assigned|completed
}

existance implies that this entry is a task

=cut

has task  => (
    is          => 'ro',
    isa         => 'HashRef',
    traits      => ['Hash'],
    required    => 1,
    default     => sub { {} },
);

=item B<is_task>

easy bool to query for tasks

=cut

has is_task     => (
    is          => 'ro',
    isa         => 'Bool',
    traits      => [ 'Bool' ],
    required    => 1,
    default     => 0,
);

=item B<parent>

the id of the parent entry

=cut

has parent  => (
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
