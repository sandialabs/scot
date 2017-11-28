package Scot::Model::Checklist;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Checklist

=head1 Description

The model of an checklist record
essentially a set holder of entries (usually tasks)
that can be inserted en mass to an alert, event, whatever

in usage, you could have a checklist to apply to various types
of workflows.

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Entriable
    Scot::Role::Hashable
    Scot::Role::Permission
    Scot::Role::Subject
    Scot::Role::Times
    Scot::Role::TLP
);

=head1 Attributes

=over 4

=item B<subject>

describe the checklist purpose
from Scot::Role::Subject

=cut

=item B<description>

=cut

has description => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'enter description...',
);

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
