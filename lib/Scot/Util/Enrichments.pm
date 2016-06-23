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

    foreach my $name (keys %{$confs} ) {
        my $href    = $confs->{$name};
        my $type    = $href->{type};

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
        }
        elsif ( $type =~ /link/ ) {

            $log->trace("Adding Link enrichment: $name");

            $meta->add_attribute(
                $name   => (
                    is          => 'rw',
                    isa         => 'HashRef',
                    default     => sub { $href },
                )
            );
        }
        else {
            die "Unsupported Enrichment Type!";
        }
    }
    $meta->make_immutable;
}

sub enrich {
    my $self    = shift;
    my $entity  = shift;
    my $force   = shift;
    my $data    = {};   # put enrichments here
    my $log     = $self->log;

    my $update_count    = 0;

    NAME:
    foreach my $enricher_name (keys %{$self->mappings}) {

        $log->trace("Looking for enrichment: $enricher_name.");


        my $enricher;
        try { 
            $enricher    = $self->$enricher_name;
        }
        catch {
            $log->error("$enricher_name does not have a defined attribute by same name in enrichments");
            next NAME;
        };

        unless ( $enricher ) {
            $data->{$enricher_name} = {
                type    => 'error',
                data    => 'invalid enricher',
            };
            next NAME;
        }

        if ( ref($enricher) eq "HASH" ) {
            if ( $enricher->{type} =~ /link/ ) {
                if (! defined $force &&
                      defined $entity->data->{$enricher_name} ) {
                    $data->{$enricher_name} = {
                        type    => 'link',
                        data    => {
                            url     => sprintf($enricher->{url},
                                               $entity->value),
                            title   => $enricher->{title},
                        },
                    };
                    $update_count++;
                }
            }
            else {
                $data->{$enricher_name} = {
                    type => 'error',
                    data => 'unsupported enrichment type',
                };
            }
        }
        else {
            if (! defined $force && 
                  defined $entity->data->{$enricher_name}) {
                next NAME;
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
