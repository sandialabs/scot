package Scot::Model::Incident;

use lib '../../../lib';
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use DateTime;
use Switch;
use DateTime::Format::Natural;
use Date::Parse;

=head1 Name

Scot::Model::Incident

=head1 Description

The model of an individual incident

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

=head1 Attributes

=over 4

=item B<promotable>

events that generated this incident
frm Scot::Role::Promotable

=cut

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

has doe_report_id => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'n/a'
);

has closed  => (
    is      => 'ro',
    isa     => 'Maybe[Epoch]',
);


=item B<reportable>

is it?

=cut

has reportable  => (
    is          => 'ro',
    isa         => 'Bool',
    traits      => ['Bool'],
    required    => 1,
    default     => 1,
    handles     => {
        make_reportable         => 'set',
        make_not_reportaable    => 'unset',
    },
);

=item B<occurred, discovered, reported>

epoch times all

=cut

has [qw(occurred discovered reported)]  => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => 0,
);

=item B<subject>

the incident subject line
from Scot::Role::Subject

=cut

=item B<status>

the status of the incident

=cut

has status => (
    is          => 'ro',
    isa         => 'valid_status',
    required    => 1,
    default     => 'open',
);

=item B<type>

the type
from Scot::Role::Type

=cut

=item B<category>

the doie category

=cut

has category  => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
    default         => 'none',
);

has security_category => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
    default         => 'NONE',
);

=item B<sensitivity>

the security sensitivity

=cut

has sensitivity  => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
    default         => 'other',
);

=item B<deadline_status>

Possible statuses: Met, Missed, Future, No deadline, Error

=cut

has deadline_status     => (
    is              => 'ro',
    isa             => 'Str',
    traits          => ['DoNotSerialize'],
    required        => 1,
    lazy            => 1,
    builder         => '_get_deadline_status',
);

sub _get_deadline_status {
    my $self    = shift;
    my $delta   = DateTime::Duration->new(seconds=>0);

    if ( $self->sensitivity eq "PII" ) {
        $delta  = DateTime::Duration->new(minutes=>35);
    }

    if ( $self->category ne "none" ) {
        if ( $self->category =~ m/1/ ) {
            $delta  = DateTime::Duration->new(hours=>1);
        }
        else {
            $delta  = DateTime::Duration->new(hours=>8);
        }
    }
    else {
        if ( $self->type =~ m/1/ ) {
            switch( $self->category ) {
                case 'Low' {
                    $delta = DateTime::Duration->new(hours=>4);
                }
                case 'Moderate' {
                    $delta = DateTime::Duration->new(hours=>1);
                }
                case 'High' {
                    $delta = DateTime::Duration->new(hours=>1);
                }
            }
        }
        elsif ( $self->type =~ m/2/ ) {
            switch ($self->category ) {
                case 'Low'  {
                    $delta  = DateTime::Duration->new(weeks=>1);
                }
                case 'Moderate' {
                    $delta  = DateTime::Duration->new(hours=>24);
                }
                case 'High' {
                    $delta  = DateTime::Duration->new(hours=>24);
                }
            }
        }
    }

    my $discovery_dt    = DateTime->from_epoch(epoch => $self->discovered);
    my $reported_dt     = DateTime->from_epoch(epoch => $self->reported);
    my $due_dt          = $discovery_dt + $delta;

    if ( $self->type =~ m/FYI|^Other/ or $delta->is_zero) {
        return "no deadline";
    }

    if ( DateTime->compare($due_dt, $reported_dt) >= 0 ) {
        if ( $self->reported ) {
            return "met";
        }
        else {
            return "future";
        }
    }
    return "missed";
}


__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
