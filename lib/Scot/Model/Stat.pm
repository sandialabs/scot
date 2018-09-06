package Scot::Model::Stat;

use lib '../../../lib';
use Moose;
use DateTime;
use namespace::autoclean;

=head1 Name

Scot::Model::Stat

=head1 Description

The model of a Stat

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';

with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
    Scot::Role::Value
);

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Hashable
    Scot::Role::Value

=head1 Attributes

=over 4

=item B<epoch>

the epoch representation 

=cut

has epoch  => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    lazy        => 1,
    builder     => '_build_epoch',
);

sub _build_epoch {
    my $self    = shift;
    my $dt      = DateTime->new(
        year    => $self->year,
        month   => $self->month,
        day     => $self->day,
        hour    => $self->hour,
        minute  => 0,
        second  => 0,
    );
    return $dt->epoch;
}

=item B<year>

The four digit year

=cut

has year    => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 1969,
);

=item B<month>

1-12, 1 = January

=cut

has month    => (
    is          => 'ro',
    isa         => 'Int',
    required   => 1,
    default     => 1,
);

=item B<day>

1-31 depending on the month

=cut

has day    => (
    is          => 'ro',
    isa         => 'Int',
    required   => 1,
    default     => 2,
);

=item B<dow>

the day of the week, 1-7 where 1= monday

=cut

has dow    => (
    is          => 'ro',
    isa         => 'Int',
    required   => 1,
    default     => 2,
);

=item B<quarter>

1 = jan, feb, mar

=cut

has quarter    => (
    is          => 'ro',
    isa         => 'Int',
    required   => 1,
    lazy        => 1,
    builder     => '_build_quarter',
);

sub _build_quarter {
    my $self    = shift;
    my $dt      = DateTime->new(
        year    => $self->year,
        month   => $self->month,
        day     => $self->day,
        hour    => 0,
        minute  => 0,
        second  => 0,
    );
    return $dt->quarter;
}

=item B<hour>

0-23

=cut

has hour    => (
    is          => 'ro',
    isa         => 'Int',
    required   => 1,
    default     => 1,
);

=item B<metric>

The string that identifies the metric type

=cut

has metric  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'unknown',
);

=item B<value>

The numerica quantity for the metric

=cut

has value   => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
    default     => 0,
);

=back

=cut

__PACKAGE__->meta->make_immutable;

1;
