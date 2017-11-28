package Scot::Model::Alert;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Alert

=head1 Description

The model of an individual alert

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Data
    Scot::Role::Entitiable
    Scot::Role::Entriable
    Scot::Role::Hashable
    Scot::Role::Historable
    Scot::Role::Permission
    Scot::Role::Parsed
    Scot::Role::Promotable
    Scot::Role::Status
    Scot::Role::Times
    Scot::Role::TLP
);

=head1 Attributes

=over 4

=item B<alertgroup>

the integer id of the alertgroup this alert belongs in

=cut

has alertgroup  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
);

=item B<status>

the status of the alert
from Scot::Role::Status
valid statuses defined by Alertstatus in Types.pm

=cut


=item B<parsed>

was this alert parsed (true = 1) otherwise we will need the original html
from Scot::Role::Parsed

=cut

=item B<data>

the hash reference to the data extraced from the alert
from Scot::Role::Data

=cut


=item B<data_with_fair>

same as data, but with detected entities wraped in spans 
(or as we say flaired)
This is tricky though, we really only want to calculate 
flair when needed because of the expense

=cut

has data_with_flair => (
    is          => 'ro',
    isa         => 'HashRef',
    traits      => [ 'Hash' ],
    required    => 1,
    default     => sub { {} },
);

=item B<columns>

the columns parsed from the data
not sure this is needed in scot like it was in vast
but tests break without it

=cut

has columns     => (
    is          => 'ro',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    default     => sub {[]},
);


__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
