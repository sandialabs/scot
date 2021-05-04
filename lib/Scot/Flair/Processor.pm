package Scot::Flair::Processor;

use Moose;

has env => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
);

has regexes => (
    is          => 'ro',
    isa         => 'Scot::Flair::Regex',
    required    => 1,
);

has scotio  => (
    is          => 'ro',
    isa         => 'Scot::Flair::Io',
    required    => 1,
);

has extractor   => (
    is          => 'ro',
    isa         => 'Scot::Flair::Extractor',
    required    => 1,
);

sub flair {
    my $self    = shift;
    my $data    = shift;
    my $timer   = $self->env->get_timer("flair_time");
    my $object  = $self->retrieve($data);
    my $results = $self->flair_object($object);
    $self->send_notifications($results);
    $self->update_stats($results);
    &$timer;
}

sub retrieve {
    my $self    = shift;
    my $data    = shift;
    my $log     = $self->env->log;
    my $io      = $self->scotio;
    my $type    = $data->{data}->{type};
    my $id      = $data->{data}->{id} + 0;

    $log->debug("[$$] worker retrieving $type $id");

    return $self->scotio->get_object($type, $id);
}

sub process_html {
    my $self    = shift;
    my $html    = shift;
    my $extractor   = $self->extractor;

    return $extractor->process_html($html);

    # return {
    #     entities    => $entities,
    #     flair       => $flair,
    # };
}

sub genspan {
    my $self    = shift;
    my $value   = shift;
    my $type    = shift;

    return  qq|<span class="entity $type" |.
            qq| data-entity-value="$value" |.
            qq| data-entity-type="$type">$value</span>|;
}

1;
