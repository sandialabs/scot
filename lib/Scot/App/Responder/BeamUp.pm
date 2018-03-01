package Scot::App::Responder::BeamUp;

use Try::Tiny;
use Data::Dumper;
use Moose;
extends 'Scot::App::Responder';

##
## beam up detected changes
## 

has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'BeamUp',
);

has wait_timeout => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    builder     => '_build_wait_timeout',
);

sub _build_wait_timeout {
    my $self    = shift;
    my $attr    = "wait_timeout";
    my $default = 120;  # seconds
    my $envname = "scot_app_responder_beamup_wait_timeout";
    return $self->get_config_value($attr, $default, $envname);
}

has share_strategy => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    builder     => '_build_share_strategy',
);

sub _build_share_strategy {
    my $self    = shift;
    my $attr    = "share_strategy";
    my $default = "most"; # [ explicit, most, all ]
    my $envname = "scot_app_responder_beamup_share_strategy";
    return $self->get_config_value($attr, $default, $envname);
}

has upstream_scot   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    builder     => '_build_upstream_scot',
);

sub _build_upstream_scot {
    my $self    = shift;
    my $attr    = "upstream_scot";
    my $default = "localhost";  # localhost will do nothing
    my $envname = "scot_app_responder_beamup_upstream_scot";
    return $self->get_config_value($attr, $default, $envname);
}

has scot_client => (
    is          => 'ro',
    isa         => 'Scot::Util::ScotClient',
    required    => 1,
    lazy        => 1,
    builder     => '_build_scot_client',
);

sub _build_scot_client {
    my $self    = shift;
    my $config  = $self->env->scot_client;
    my $client  = Scot::Util::ScotClient->new(%$config);
    return $client;
}

sub process_message {
    my $self        = shift;
    my $pm          = shift;
    my $href        = shift;
    my $action      = $href->{action};
    my $type        = $href->{data}->{type};
    my $id          = $href->{data}->{id};
    my $log         = $self->log;

    $log->debug("[Wkr $$] Processing Message $action $type $id");

    if ( $action eq "create" ) {
        
        if ( $self->share_strategy eq "all" ) {
            $self->beam($action, $type, $id);
        }
        elsif ( $self->share_strategy eq "most" ) {
            sleep $self->wait_timeout;
            if ( $self->can_share($type, $id) ) {
                $self->beam($action, $type, $id);
            }
        }
        else {
            if ( $self->can_share($type, $id) ) {
                $self->beam($action, $type, $id);
            }
        }
        return;
    }

    if ( $action eq "update" or $action eq "delete" ) {
        if ( $self->can_share($type, $id) ) {
            $self->beam($action, $type, $id);
        }
        return;
    }

}

sub can_share {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $obj     = $self->get_obj($type, $id);

    if ( $obj->is_sharable ) {
        if ( $obj->tlp_permits_sharing ) {
            return 1;
        }
    }
    return undef;
}

sub get_obj {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $colname = ucfirst($type);
    my $col     = $self->env->mongo->collection($colname);
    my $obj     = $col->find_iid($id);
    return $obj;
}

sub beam {
    my $self    = shift;
    my $action  = shift;
    my $type    = shift;
    my $id      = shift;
    my $client  = $self->scot_client;
    my $obj     = $self->get_obj($type,$id);
    my $location    = $self->env->location;

    my $uri = "/scot/api/v2/" . $type;
    my $href    = $obj->as_hash;
    
    if (! defined $href->{location} ) {
        $href->{location} = $location;
    }

    my $json;

    if ( $action eq "create" ) {
        $json = $client->post($uri, $href);
    }
    elsif ( $action eq "update" ) {
        $uri .= "/$id";
        $json = $client->put($uri, $href);
    }
    elsif ( $action eq "delete" ) {
        $uri .= "/$id";
        $json = $client->delete($uri,$href);
    }
    else {
        die "Unsupported API action $action";
    }

    # Error checking

}


1;
