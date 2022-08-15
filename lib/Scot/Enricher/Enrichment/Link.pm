package Scot::Enricher::Enrichment::Link;

use namespace::autoclean;
use Moose;
extends 'Scot::Enricher::Enrichment';

has url => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_url',
);

sub _build_url {
    my $self    = shift;
    my $conf    = $self->conf;
    return $conf->{url};
}

has title   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_title',
);

sub _build_title {
    my $self    = shift;
    my $conf    = $self->conf;
    return $conf->{title};
}

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
    my $data    = {
        'type'  => 'link',
        'data'  => {
            url     => sprintf($self->url, $value),
            title   => $self->title,
        }
    };
    my $elapsed = &$timer;
    $self->env->log->debug(ref($self). " enrich Elaspsed time: $elapsed");
    return $data;
}

1;


