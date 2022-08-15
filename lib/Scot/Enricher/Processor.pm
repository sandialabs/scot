package Scot::Enricher::Processor;

use Module::Runtime qw(require_module);
use Try::Tiny;
use Data::Dumper;
use Moose;

has env => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required=> 1,
);

has scotio => (
    is      => 'ro',
    isa     => 'Scot::Enricher::Io',
    required=> 1,
);

has enrichments => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
);

sub process_item {
    my $self    = shift;
    my $json    = shift;
    my $io      = $self->scotio;
    my $log     = $self->env->log;

    my $type    = $json->{data}->{type};
    my $id      = $json->{data}->{id} + 0;

    $log->debug("Processing Item $type $id");

    my $timer   = $self->env->get_timer('retrieve_item');
    my $entity  = $io->retrieve_item('entity', $id);
    my $elapsed = &$timer;
    $log->debug("Retrieve Entity $id Elapsed Timer: $elapsed");

    if ( ! defined $entity ) {
        $log->warn("Entity $id Not FOUND. Skipping...");
        return;
    }
    
    my %updates = $self->process_enrichments($entity);

    $self->update_entity_data($id, \%updates);
}

sub process_enrichments {
    my $self    = shift;
    my $entity  = shift;
    my %updates = ();
    my $log     = $self->env->log;
    my $type    = $entity->type;

    $log->debug("processing enrichments for $type entity ".$entity->id);

    foreach my $enrichment (@{$self->enrichments}) {
        if (! $enrichment->will_enrich($type) ) {
            $log->trace("enrichment ".ref($enrichment)." does not enrich $type");
            next;
        }
        $log->debug("enriching with ".ref($enrichment));
        my $ename   = lc((split(/::/,ref($enrichment)))[-1]);
        my $data    = $enrichment->enrich($entity);
        # hack
        if ( $ename eq "blocklist" ) {
            $ename = "blocklist3";
        }
        $updates{$ename} = $data;
    }

    my $update_count = scalar(keys %updates);
    $log->debug("$update_count updates for entity ".$entity->{value});
    return wantarray ? %updates : \%updates;
}

sub get_applicable_enrichments {
    my $self    = shift;
    my $entity  = shift;
    my $map     = $self->env->enricher_mapping;
    my $log     = $self->env->log;

    $log->trace("enrichment map ",{filter=>\&Dumper, value => $map});

    my $etype       = $entity->type;

    $log->debug("entity type is $etype");

    my $emodules    = $map->{$etype};

    return [] unless(defined $emodules and scalar(@$emodules) > 0);
    return $emodules;
}

sub get_enrichment_config {
    my $self    = shift;
    my $name    = shift;
    my $log     = $self->env->log;
    my $config  = $self->env->enrichers;
    $config->{$name}->{name} = $name;

    $log->debug("Enrichment $name CONFIG is ",{filter=>\&Dumper, value=>$config->{$name}});
    return $config->{$name};
}



sub update_entity_data {
    my $self       = shift;
    my $entity_id  = shift;
    my $updates    = shift;
    my $io         = $self->scotio;
    my $log         = $self->env->log;

    $log->debug("Applying ".scalar(keys %$updates)." enrichments to entity $entity_id");
    $log->debug({filter=>\&Dumper, value => $updates});

    $io->apply_enrichment_data($entity_id, $updates);
}

1;

