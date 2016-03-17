package Scot::Model::Einfo;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Einfo

=head1 Description

The model of Entity INFO.  Entities can have information that changes overtime.  This allows us to 
keep snapshot in time captures of that information.  For example, a domain can change registration.
An IP can change GEOIP. etc.

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
);

=head1 Attributes

=over 4

=item B<entity>

the integer id of the entity this information is related to

=cut

has entity  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
);

=item B<timestamp>

seconds since unix epoch when this data was obtained and stored in DB.

=cut

has when    => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => sub { time(); },
);

=item B<infotype>

The type of info record, e.g.  DNS, GeoIP, etc.

=cut

has infotype    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'unknown',
);

=item B<info>

the actual record, as a hashref

=cut

has info    => (
    is          => 'ro',
    isa         => 'HashRef',
    traits      => [ 'Hash' ],
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

