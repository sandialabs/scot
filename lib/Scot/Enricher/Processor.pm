package Scot::Enricher::Processor;

use Module::Runtime qw(require_module);
use Try::Tiny;
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

sub process_item {
    my $self    = shift;
    my $json    = shift;
    my $io      = $self->scotio;
    my $log     = $self->env->log;

    my $type    = $json->{data}->{type};
    my $id      = $json->{data}->{id} + 0;

    $log->debug("Processing Item $type $id");

    my $entity    = $io->retrieve_entity_href($id);
    
    my @updates = $self->process_enrichments($entity);

    $self->update_entity_data($id, @updates);
}

sub process_enrichments {
    my $self    = shift;
    my $entity  = shift;
    my @updates = ();

    my @mappings    = $self->get_applicable_enrichments($entity);

    foreach my $enricher_name (@mappings) {
        my $enricher_config = $self->get_enrichment_config($enricher_name);
        next unless defined $enricher_config;
        push @updates, $self->enrich($entity, $enricher_config);
    }

    return wantarray ? @updates : \@updates;
}

sub get_applicable_enrichments {
    my $self    = shift;
    my $entity  = shift;
    my $map     = $self->env->enricher_mapping;
    my $etype   = $entity->type;
    my $emodules   = $map->{$etype};

    return [] unless(defined $emodules and scalar(@$emodules) > 0);
    return $emodules;
}

sub get_enrichment_config {
    my $self    = shift;
    my $name    = shift;
    my $config  = $self->env->enrichers;
    $config->{name} = $name;
    return $config->{$name};
}

sub enrich {
    my $self    = shift;
    my $entity  = shift;
    my $config  = shift;
    my $type    = $config->{type};
    my @enrichments = ();

    if ( $type =~ /link/i ) {
        my $edata = $self->process_link_type($entity, $config);
        push @enrichments, $edata if (defined $edata);
    }

    if ( $type =~ /native/i ) {
        my $edata = $self->process_native_type($entity, $config);
        push @enrichments, $edata if (defined $edata);
    }
    return wantarray ? @enrichments : \@enrichments;
}

sub process_link_type {
    my $self    = shift;
    my $entity  = shift;
    my $config  = shift;
    my $name    = $config->{name};
    my $field   = $config->{field};
    my $value   = $entity->{$field};
    my $nopop   = (defined $config->{nopopup} && $config->{nopopup} == 1) ? 1 : 0;
    my $data    = {
        $name => {
            type    => 'link',
            data    => {
                url     => sprintf($config->{url}, $value),
                title   => $config->{title},
                nopopup => $nopop,
            },
        },
    };
    return $data;
}

sub process_native_type {
    my $self    = shift;
    my $entity  = shift;
    my $config  = shift;
    my $name    = $config->{name};
    
    my $emod    = $self->load_enricher($config);
    if (defined $emod and ref($emod) eq $config->{module}) {
        my $data    = $emod->enrich($entity);
        return {
            data    => $data,
            type    => 'data',
        };
    }
    return undef;
}

sub load_enricher {
    my $self    = shift;
    my $config  = shift;

    my $modname     = $config->{module};
    my $modconfig   = $config->{config};

    my $instance = try {
        require_module($modname);
        return $modname->new(config => $modconfig);
    }
    catch {
        $self->env->log->error("Failed to load and instantiate module $modname!: $_");
        return undef;
    };
    return $instance;
}

sub update_entity_data {
    my $self       = shift;
    my $entity_id  = shift;
    my @updates    = @_;
    my $io         = $self->scotio;

    $io->apply_enrichment_data($entity_id, @updates);
}

1;

