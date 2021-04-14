package Scot::Model::Remoteflair;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::RemoteFlair

=head1 Description

The model of an dispatch feed

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Data
    Scot::Role::Times
    Scot::Role::Hashable
);

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Data;
    Scot::Role::Times
    Scot::Role::Hashable

=head1 Attributes

=over 4

=item B<command>

the command the browser extension wants: flair or insert 

=cut

has command => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
    default => 'flair',
);

=item B<md5>

md5 hash of the html content sent

=cut

has md5 => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<uri>

The uri that was sent

=cut

has uri => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'unknown',
);

has html    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '',
);

=item status

requested => browser extension sent in request.
processing => flair engine is working
ready   => browser extension can requeqest results 
error   => there was an error in processing

=cut

has status  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'requested',
);

=item results 

the results of the flair engine

=cut

has results => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub {{}},
);



__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
