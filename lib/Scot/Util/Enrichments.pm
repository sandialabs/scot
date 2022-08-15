package Scot::Util::Enrichments;

use Module::Runtime qw(require_module compose_module_name);

use Data::Dumper;
use Try::Tiny;
use Moose;
extends 'Scot::Util';


has mappings    => (
    is          => 'ro',
    isa         => 'HashRef',
    lazy        => 1,
    required    => 1,
    # default     => sub { {} },
    builder     => '_build_mappings',
);

sub _build_mappings {
    my $self    = shift;
    my $attr    = 'mappings';
    my $default = {};
    return $self->get_config_value($attr,$default);
}

has enrichers     => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    # default     => sub { {} },
    builder     => '_build_enrichers',
);

sub _build_enrichers {
    my $self    = shift;
    my $attr    = 'enrichers';
    my $default = {};
    return $self->get_config_value($attr,$default);
}

sub BUILD {
    my $self    = shift;
    my $maps    = $self->mappings;
    my $confs   = $self->enrichers;
    my $meta    = $self->meta;
    my $log     = $self->log;
    $meta->make_mutable;

    $log->debug("Building Enrichments...");

    ENRICHMENT:
    foreach my $name (keys %{$confs} ) {
        my $href    = $confs->{$name};
        my $type    = $href->{type};

        $log->trace("Type is $type");

        if ( $type eq "native" ) {

            $log->trace("Adding native enrichment: $name");

            my $module  = $href->{module};
            my $config  = $href->{config};
            unless (defined $config) {
                $config = {};
            }

            $config->{log}  = $log;

            $log->trace("Module $module with config ",{filter=>\&Dumper, value=>$config});

            require_module($module);
            $meta->add_attribute(
                $name   => (
                    is      => 'rw',
                    isa     => $module,
                )
            );
            my $instance  = $module->new($config);

            if ( defined $instance ) {
                $self->$name($instance);
            }
            next ENRICHMENT;
        }

        if ( $type eq 'external_link' or $type eq 'internal_link' ) {

            $log->trace("Adding Link enrichment: $name");

            $meta->add_attribute(
                $name   => (
                    is          => 'rw',
                    isa         => 'HashRef',
                )
            );
            $log->trace("creating attribute $name with value ",
                        { filter => \&Dumper, value => $href} );
            $self->$name($href);
        }
        else {
            warn "Unsupported Enrichment Type!";
        }
    }
    $meta->make_immutable;
    $log->trace("Enrichment is ",{filter=>\&Dumper,value=>$self});
}

sub enrich {
    my $self    = shift;
    my $entity  = shift;
    my $force   = 1;    # always refresh data
    my $data    = {};   # put enrichments here
    my $log     = $self->log;
    my $update_count    = 0;

    if (ref($entity) eq "Scot::Model::Entity") {
        $entity = $entity->as_hash;
    }

    my $etype   = $entity->{type};

    $log->debug("Entity ". $entity->{value}. " Type is $etype");

    my $eset    = $self->mappings->{$etype};

    unless ($eset) {
        $log->error("ERROR enity set is not defined!");
        $eset = [];
    }
    else {
        $log->debug("Enrichments available for type: ".  join(', ',@$eset));
    }

    NAME:
    foreach my $enricher_name (@{$eset}) {

        $log->trace("Looking for enrichment: $enricher_name.");

        my $enricher = try { 
            $self->$enricher_name;
        }
        catch {
            $log->error("$enricher_name does not have a defined attribute by same name in enrichments");
            return undef;
        };

        unless ( $enricher ) {
            $log->error("invalid enricher $enricher_name!");
            #$data->{$enricher_name} = {
            #    type    => 'error',
            #    data    => 'invalid enricher',
            #};
            next NAME;
        }

        $log->trace("Enricher Hash is ",{filter=>\&Dumper, value=>$enricher});

        if ( ref($enricher) eq "HASH" ) {

            if ( $enricher->{type} =~ /link/i ) {

                my $field   = $enricher->{field};
                my $value   = $entity->{$field};

                if ( defined $entity->{data}->{$enricher_name} ) {
                    if ( $force ) {
                        $data->{$enricher_name} = {
                            type    => 'link',
                            data    => {
                                url => sprintf($enricher->{url}, $value),
                                title   => $enricher->{title},
                            },
                        };
                        if ( defined $enricher->{nopopup} ) {
                            $data->{$enricher_name}->{data}->{nopopup} = $enricher->{nopopup};
                            $log->debug("enricher now ",{filter=>\&Dumper, value=>$data});
                        }
                        $update_count++;
                    }
                }
                else {
                    $data->{$enricher_name} = {
                        type    => 'link',
                        data    => {
                            url => sprintf($enricher->{url}, $value),
                            title   => $enricher->{title},
                            
                        },
                    };
                    if ( defined $enricher->{nopopup} ) {
                        $data->{$enricher_name}->{data}->{nopopup} = $enricher->{nopopup};
                        $log->debug("enricher now ",{filter=>\&Dumper, value=>$data});
                    }
                    $update_count++;
                }
            }
            else {
                $log->error("unsupported enrichment type!");
                $data->{$enricher_name} = {
                    type => 'error',
                    data => 'unsupported enrichment type',
                };
            }
        }
        else {
            # this is for native modules

            if ( defined $entity->{data}->{$enricher_name}) {
                # we have a cache of enrichment data for this type already
                if ( ! defined $force ) {
                    # so unless $force is defined, do not refresh
                    next NAME;
                }
            }
            my $entity_data;
            try {
                $entity_data = $enricher->get_data($entity->{type}, 
                                                  $entity->{value});
            }
            catch {
                $log->error("Failed to Get Enrichment data for ",
                            { filter => \&Dumper, value => $entity });
                undef $entity_data;
            };

            if ($entity_data) {
                $data->{$enricher_name} = {
                    data    => $entity_data,
                    type    => 'data',
                };
                $update_count++;
            }
            else {
                #$data->{$enricher_name} = {
                #    type    => 'error',
                #    data    => 'no data',
                #};
            }
        }
    }
    return $update_count, $data;
}


1;
