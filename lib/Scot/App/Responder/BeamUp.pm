package Scot::App::Responder::BeamUp;
use lib '../../../../lib';
use Try::Tiny;
use Data::Dumper;
use Moose;
use Scot::Util::ScotClient;
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
    my $client  = Scot::Util::ScotClient->new(
        config => $config,
        env    => $self->env,
    );
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

    my @permitted_actions   = qw(created updated deleted);

    if ( grep {/$action/} @permitted_actions ) {
        my $strategy    = $self->share_strategy;
        $log->debug("Permitted action, share strategy = $strategy");
        if ( $strategy eq "all" or $strategy eq "explicit" ) {
            # immediately share
            return $self->beam($action, $type, $id);
        }
        if ( $strategy eq "delay" ) {
            # share after a delay period
            $log->debug("sleeping until wait_timeout is reached");
            sleep $self->wait_timeout;
            return $self->beam($action, $type, $id);
        }

        $log->error("Unexpected sharing strategy: $strategy");
    }
    else {
        $log->error("Action $action not a permitted action.");
    }

}

sub can_share {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $obj     = $self->get_obj($type, $id);

    if ( $obj->meta->does_role("Scot::Role::Sharable") ) {
        if ( $obj->is_shareable ) {
            if ( $obj->tlp_permits_sharing ) {
                return 1;
            }
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
    my $log     = $self->env->log;

    $log->debug("Attempting to beam up record");

    # check if object is marked ok to share
    if ( $self->can_share($type, $id, $obj) ) {

        $log->debug("sharing is permitted");

        my $endpt =  $type;
        my $href    = $obj->as_hash;

        
        if (! defined $href->{location} ) {
            $href->{location} = $location;
        }

        $log->debug("object hash is ",{filter=>\&Dumper,value=>$href});

        my $json;

        $log->trace("action is $action");

        if ( $action eq "created" ) {
            $json = $client->post($endpt, $href);
            $log->trace("returned json ",{filter=>\&Dumper,value=>$json});
            return $id;
        }
        elsif ( $action eq "updated" ) {
            $endpt .= "/$id";
            $json = $client->put($endpt, $href);
            $log->trace("returned json ",{filter=>\&Dumper,value=>$json});
            return $id;
        }
        elsif ( $action eq "delete" ) {
            $endpt .= "/$id";
            $json = $client->delete($endpt,$href);
            $log->trace("returned json ",{filter=>\&Dumper,value=>$json});
            return $id;
        }
        else {
            return "Unsupported API action $action";
        }

        # Error checking
    }
    else {
        $log->error("Object is marked do not share or bad tlp, not shared");
        return "Sharing not permitted";
    }

}


1;
