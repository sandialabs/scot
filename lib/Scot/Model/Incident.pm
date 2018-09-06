package Scot::Model::Incident;

use lib '../../../lib';
use Moose;
use Moose::Util::TypeConstraints;
use DateTime;
use Switch;
use DateTime::Format::Natural;
use Date::Parse;
use namespace::autoclean;

=head1 Name

Scot::Model::Incident2

=head1 Description

The model for an individual incident.
(This is a replacement for old, sandia specific incident. it
can handle changes to the incident data more gracefully)

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Entriable
    Scot::Role::Events
    Scot::Role::Hashable
    Scot::Role::Historable
    Scot::Role::Permission
    Scot::Role::Promotable
    Scot::Role::Sources
    Scot::Role::Subject
    Scot::Role::Tags
    Scot::Role::Type
    Scot::Role::TLP
    Scot::Role::Times
);

enum 'valid_status', [ qw(open closed) ];

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Entriable
    Scot::Role::Events
    Scot::Role::Hashable
    Scot::Role::Historable
    Scot::Role::Permission
    Scot::Role::Promotable
    Scot::Role::Sources
    Scot::Role::Subject
    Scot::Role::Tags
    Scot::Role::Type
    Scot::Role::TLP
    Scot::Role::Times

=head1 Attributes

=over 4

=item B<promoted_from>

the event id that promted this incident
[] implies not as a result from promotion

=cut

has promoted_from => (
    is          => 'ro',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    default     => sub {[]},
);

=item B<status>

The status (open, closed...) 

=cut

has status  => ( 
    is          => 'ro',
    isa         => 'valid_status',
    required    => 1,
    default     => 'open',
);

=item B<created, updated, when>

The creation time, the last updated time, and a user modifiable time stamp all in seconds since unix epoch

=item B<occurred, discovered, reported>

The time the incident occurred, the time it was discovered, and the time it was reported all in seconds since unix epoch

=cut

has [qw(occurred discovered reported closed)] => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => 0,
);

=item B<subject>

from Scot::Role::Subject.  String representing a subject line for this incident

=item B<data_fmt_ver>

Incidents might change over time, this value must match a key in scot.cfg.pl "forms" section.

=cut

has data_fmt_ver    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'incident_v2',
);

=item B<data>

Now the data about the incident is stored inside this attribute.  

=cut

has data    => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { {} },
);

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    







