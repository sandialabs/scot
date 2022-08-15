package Scot::Enricher::Enrichment;

use Data::Dumper;
use Moose;

has env => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
);

has conf => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

has enrichables => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_enrichables',
);

sub _build_enrichables {
    my $self    = shift;
    my $conf    = $self->conf;
    return $conf->{enrichables};
}

sub will_enrich {
    my $self        = shift;
    my $entity_type = shift;
    my $log         = $self->env->log;
    my $enrichables = $self->enrichables;
    return grep {/$entity_type/} @{$self->enrichables};
}

1;
