package Scot::Model::File;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::File

=head1 Description

The model of an individual File

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Data;
    Scot::Role::Permission
    Scot::Role::Target
    Scot::Role::Times
    Scot::Role::TLP
    Scot::Role::Hashable
);

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Data;
    Scot::Role::Permission
    Scot::Role::Target
    Scot::Role::Times
    Scot::Role::TLP
    Scot::Role::Hashable

=head1 Attributes

=over 4

=item B<entry_target>

cache of the target of the entry
that the file is associated with
to prevent an expensive secondary db lookup

=cut

has entry_target => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { {} },
);

=item B<filename>

guess

=cut

has filename  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<size>

the bytes

=cut

has size  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

=item B<notes>

string field for short notes about file

=cut

has notes   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => ' ',
);

=item B<entry>

the id of the entry that has created when file was uploaded

=cut

has entry   => (
    is          => 'ro',
    isa         => 'Maybe[iid]',
    required    => 0,
);

=item B<directory> 

the directory where the file is located

=cut

has directory   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '/',
);

=item B<md5,sha1,sha256>

the md5, sha1, sha256 hashes of the file

=cut

has [qw(md5 sha1 sha256)] => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'not calculated',
);

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
