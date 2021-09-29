package Scot::Enricher::Enrichment::Binip;

use namespace::autoclean;
use Moose;
use Net::IP;
extends 'Scot::Enricher::Enrichment';

has field   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_field',
);

sub _build_field {
    my $self    = shift;
    my $conf    = $self->conf;
    return $conf->{field};
}

sub enrich {
    my $self    = shift;
    my $term    = shift;
    my $field   = $self->field;
    my $value   = $term->$field;
    my $timer   = $self->env->get_timer(ref($self)."_enrich");

    my $ip  = Net::IP->new($value);
    my $data    = $ip->binip;

    my $elapsed = &$timer;
    $self->env->log->debug(ref($self). " enrich Elaspsed time: $elapsed");
    return $data;
}

1;


