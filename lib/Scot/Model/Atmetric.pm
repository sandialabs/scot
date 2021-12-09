package Scot::Model::Atmetric;

use lib '../../../lib';
use Moose;
use DateTime;
use namespace::autoclean;

=head1 Name

Scot::Model::Stat

=head1 Description

The model of a Alerttype Stat

=cut

extends 'Scot::Model';

with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
);

=head1 Attributes

=over 4

=item B<alerttype>

The string that matches the "subject" of the alert

=cut

has alerttype  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'unknown',
);

=item B<year>

The four digit integer representation of the year this metric occurred

=cut

has year    => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 1969,
);

=item B<month>

The integer representation of the month.  1 = January

=cut

has month    => (
    is          => 'ro',
    isa         => 'Int',
    required   => 1,
    default     => 1,
);

=item B<day>

the integer representation of the day.  1 through 31

=cut

has day    => (
    is          => 'ro',
    isa         => 'Int',
    required   => 1,
    default     => 2,
);

=item B<dow> 

The integer day of the week 1 = monday

=cut

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

=item B<quarter>

The quarter of the year.  (Jan - March = 1)

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
    return $self->dt->quarter;
}

=item B<dt>

The perl datetime object based on the values above

=cut

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

=item B<hour>

The hour of the day 0-23

=cut

has hour    => (
    is          => 'ro',
    isa         => 'Int',
    required   => 1,
    default     => 1,
);

=item B<rt_sum>

the sum of all response times in this hour

=cut

has rt_sum   => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
    default     => 0,
);

=item B<rt_count>

The number of alerts with response times in this hour

=cut

has rt_count   => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
    default     => 0,
);

=item B<promoted>

The number of times this alerttype was promoted to an event

=cut

has promoted    => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
    default     => 0,
);

=item B<incident>

the number of times this alerttype was promoted to an event, and then incident

=cut

has incident   => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
    default     => 0,
);

=item B<count>

The number of times this alerttype was received in this hour

=cut

has count   => (
    is      => 'ro',
    isa     => 'Num',
    required    => 1,
    default => 0,
);

=item B<open>

the number of open alerts of this alerttype during this hour

=cut

has open    => (
    is      => 'ro',
    isa     => 'Num',
    required    => 1,
    default => 0,
);

=item B<closed>

The number of closed alerts of this alerttype durning this hour

=cut

has closed    => (
    is      => 'ro',
    isa     => 'Num',
    required    => 1,
    default => 0,
);

=back

=cut

sub get_memo {
    my $self    = shift;
    return '';
}

__PACKAGE__->meta->make_immutable;

1;
