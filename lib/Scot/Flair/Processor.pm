package Scot::Flair::Processor;

use Data::Dumper;
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
    if ( defined $object ) {
        my $results = $self->flair_object($object);
        $self->send_notifications($object, $results);
        $self->update_stats($results);
    }
    else {
        $self->env->log->error("Unable to retrieve object ",
            {filter=>\&Dumper, value => $data});
    }
    &$timer;
}

sub update_stats {
    my $self    = shift;
    my $results = shift;

}

sub send_notifications {
    my $self    = shift;
    my $object  = shift;
    my $results = shift;
    my $io      = $self->scotio;

    my $type = $self->get_type($object);

    # need to send message to /queue/enricher for each entity
    foreach my $entity (@{$results->{entities}}) {
        my $entityid    = $io->get_entity_id($entity);
        if ( defined $entityid ) {
            $io->send_mq('/queue/enricher',{
                action  => 'updated',
                data    => {
                    type    => 'entity',
                    id      => $entityid,
                    who     => 'scot-flair',
                },
            });
        }
        else {
            $self->env->log->error("Entity $entity->{value} $entity->{type} not found, enricher queue message not sent!");
        }
    }
    $io->send_mq("/topic/scot", {
        action  => 'updated',
        data    => {
            type    => $type,
            id      => $object->id,
        },
    });
}

sub get_type {
    my $self    = shift;
    my $object  = shift;
    my @parts   = split(/::/,ref($object));
    return lc($parts[-1]);
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
