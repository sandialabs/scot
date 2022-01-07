package Scot::HtmlRestricter;

use strict;
use warnings;
use HTML::Restrict;
use Moose;

has rules   => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub {{
        span        => [ {class => qr{^entity }}, 'data-entity-type', 'data-entity-value' ],
        br          => [],
        svg         => [qw(height viewbox width xmlns)],
        polyline    => [qw(fill points stroke stroke-linecap stroke-width)],
        div         => [],
    }},
);

has hr  => (
    is          => 'ro',
    isa         => 'HTML::Restrict',
    required    => 1,
    lazy        => 1,
    builder     => '_build_hr',
);

sub _build_hr {
    my $self    = shift;
    my $rules   = $self->rules;
    return HTML::Restrict->new(rules => $rules);
}

sub clean {
    my $self    = shift;
    my $html    = shift;
    return $self->hr->process($html);
}

1;


