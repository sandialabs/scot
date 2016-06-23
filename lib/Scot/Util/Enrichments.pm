package Scot::Util::Enrichments;

use Module::Runtime qw(require_module compose_module_name);

use Data::Dumper;
use Try::Tiny;
use Moose;

# config is passed in the new call

has log         => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
);

has mappings    => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { {} },
);

has configs     => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { {} },
);

sub BUILD {
    my $self    = shift;
    my $maps    = $self->mappings;
    my $confs   = $self->configs;
    my $meta    = $self->meta;
    my $log     = $self->log;
    $meta->make_mutable;

    $log->debug("Building Enrichments...");

    ENRICHMENT:
    foreach my $name (keys %{$confs} ) {
        my $href    = $confs->{$name};
        my $type    = $href->{type};

        $log->debug("Type is $type");

        if ( $type eq "native" ) {

            $log->trace("Adding native enrichment: $name");

            my $module  = $href->{module};
            my $config  = $href->{config};
            unless (defined $config) {
                $config = {};
            }

            $config->{log}  = $log;

            $log->debug("Module $module with config ",{filter=>\&Dumper, value=>$config});

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
            $self->$name($href);
        }
        else {
            die "Unsupported Enrichment Type!";
        }
    }
    $meta->make_immutable;
    $log->debug("Enrichment is ",{filter=>\&Dumper,value=>$self});
}

sub enrich {
    my $self    = shift;
    my $entity  = shift;
    my $force   = shift;
    my $data    = {};   # put enrichments here
    my $log     = $self->log;

    my $update_count    = 0;

    my $etype   = $entity->type;

    $log->debug("Entity ". $entity->value. " Type is $etype");

    my $eset    = $self->mappings->{$etype};

    NAME:
    foreach my $enricher_name (@{$eset}) {

        $log->debug("Looking for enrichment: $enricher_name.");

        my $enricher;
        try { 
            $enricher    = $self->$enricher_name;
        }
        catch {
            $log->error("$enricher_name does not have a defined attribute by same name in enrichments");
            next NAME;
        };

        unless ( $enricher ) {
            $log->error("invalid enricher $enricher_name!");
            $data->{$enricher_name} = {
                type    => 'error',
                data    => 'invalid enricher',
            };
            next NAME;
        }

        $log->debug("Enricher Hash is ",{filter=>\&Dumper, value=>$enricher});

        if ( ref($enricher) eq "HASH" ) {

            if ( $enricher->{type} =~ /link/i ) {

                if ( defined $entity->data->{$enricher_name} ) {
                    if ( $force ) {
                        $data->{$enricher_name} = {
                            type    => 'link',
                            data    => {
                                url => sprintf($enricher->{url}, $entity->value),
                                title   => $enricher->{title},
                            },
                        };
                        $update_count++;
                    }
                }
                else {
                    $data->{$enricher_name} = {
                        type    => 'link',
                        data    => {
                            url => sprintf($enricher->{url}, $entity->value),
                            title   => $enricher->{title},
                        },
                    };
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

            if ( defined $entity->data->{$enricher_name}) {
                # we have a cache of enrichment data for this type already
                if ( ! defined $force ) {
                    # so unless $force is defined, do not refresh
                    next NAME;
                }
            }
            my $entity_data = $enricher->get_data($entity->type, 
                                                  $entity->value);
            if ($entity_data) {
                $data->{$enricher_name} = {
                    data    => $entity_data,
                    type    => 'data',
                };
                $update_count++;
            }
            else {
                $data->{$enricher_name} = {
                    type    => 'error',
                    data    => 'no data',
                };
            }
        }
    }
    return $update_count, $data;
}


1;
