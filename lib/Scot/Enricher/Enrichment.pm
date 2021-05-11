package Scot::Enricher::Enrichment;

use Moose;

has config => (
    is      => 'ro',
    isa     => 'HashRef',
    required=> 1,
);

has env => (
    is      => 'ro',
    isa     => 'Scot::Env',
);

1;
