package Scot::Model::Atmetric;

use lib '../../../lib';
use Moose;
use DateTime;
use namespace::autoclean;

=head1 Name

Scot::Model::Stat

=head1 Description

The model of a Stat

=cut

extends 'Scot::Model';

with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
);

=head1 Attributes

=over 4

=cut

has alerttype  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'unknown',
);

has year    => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 1969,
);

has month    => (
    is          => 'ro',
    isa         => 'Int',
    required   => 1,
    default     => 1,
);

has day    => (
    is          => 'ro',
    isa         => 'Int',
    required   => 1,
    default     => 2,
);

has dow    => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_build_dow',
);

sub _build_dow {
    my $self    = shift;
    return $self->dt->dow;
}

has quarter    => (
    is          => 'ro',
    isa         => 'Int',
    required   => 1,
    lazy        => 1,
    builder     => '_build_quarter',
);

sub _build_quarter {
    my $self    = shift;
    return $self->dt->quarter;
}

has dt  => (
    is          => 'ro',
    isa         => 'DateTime',
    required    => 1,
    lazy        => 1,
    builder     => '_build_dt',
);

sub _build_dt {
    my $self    = shift;
    my $dt      = DateTime->new(
        year    => $self->year,
        month   => $self->month,
        day     => $self->day,
        hour    => 0,
        minute  => 0,
        second  => 0
    );
    return $dt;
}

has hour    => (
    is          => 'ro',
    isa         => 'Int',
    required   => 1,
    default     => 1,
);

has rt_sum   => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
    default     => 0,
);
has rt_count   => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
    default     => 0,
);

has promoted    => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
    default     => 0,
);

has incident   => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
    default     => 0,
);

has count   => (
    is      => 'ro',
    isa     => 'Num',
    required    => 1,
    default => 0,
);

has open    => (
    is      => 'ro',
    isa     => 'Num',
    required    => 1,
    default => 0,
);

has closed    => (
    is      => 'ro',
    isa     => 'Num',
    required    => 1,
    default => 0,
);



__PACKAGE__->meta->make_immutable;

1;
