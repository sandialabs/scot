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
    Scot::Role::Historable
    Scot::Role::Parsed
    Scot::Role::Permission
    Scot::Role::Target
    Scot::Role::Times
    Scot::Role::TLP
);

=head1 Attributes

=over 4

=item B<class>

The "type" of entry.  
"summary"   => the summary boxes
"alert",    => alert recap box
"entry"     => normal user entered
"task"      => a task entry
"file"      => holder of files uploaded entries
"json"      => json data

=cut

has class   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'entry',
);

=item B<metadata>

data about the entry.
if entry is task then it is a 
hash of {
    task => {
        when    => seconds_epoch,
        who     => username,
        status  => open|assigned|completed
    }
}

=cut

has metadata  => (
    is          => 'ro',
    isa         => 'HashRef',
    traits      => ['Hash'],
    required    => 1,
    default     => sub { {} },
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
