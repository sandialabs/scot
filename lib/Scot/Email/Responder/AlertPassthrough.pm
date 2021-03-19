package Scot::Email::Responder::AlertPassthrough;

use strict;
use warnings;
use Try::Tiny;
use Data::Dumper;
use Module::Runtime qw(require_module compose_module_name);
use Moose;
extends 'Scot::Email::PFResponder';

has name => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
    default => 'AlertEmailPassthrough',
);

has parsers => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    builder     => '_build_parsers',
);

sub _build_parsers {
    my $self                = shift;
    my @parser_class_names  = (qw(
        Scot::Email::Parser::PassThrough
    ));    
    my @parsers = ();
    foreach my $cname (@parser_class_names) {
        require_module($cname);
        push  @parsers, $cname->new({ env => $self->env });
    }
    return wantarray ? @parsers : \@parsers;
}

sub _build_max_workers {
    my $self        = shift;
    my $package     = __PACKAGE__;
    my $responder   = $self->get_config_value("responders", undef, undef);
    my $workers     = 1;
    if (defined $responder) {
        if (defined $responder->{workers} ) {
            $workers     = $responder->{workers};
        }
    }
    return $workers;
}

has create_method => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'create_via_mongo',
);

sub process_message {
    my $self    = shift;
    my $pm      = shift;
    my $href    = shift;
    my $data    = $href->{email};
    my $log     = $self->env->log;

    $log->debug("[Wkr $$] Processing Alert");

    if ( $self->is_health_check($data) ) {
        $log->warn("[Wkr $$] Finished: Skipping Health Check Message");
        return 1;
    }

    PARSE:
    foreach my $parser (@{$self->parsers}) {

        if ( ! $parser->will_parse($data) ) {
            $log->warn(ref($parser)." will not parse this data");
            next PARSE;
        }

        if ( my $count = $self->create_alertgroup($parser, $data) ) {
            $log->debug("Created $count alertgroup(s)");
            return 1;
        }

        $log->error("Failed to create alertgroup from ",
                    { filter => \&Dumper, value => $data });
    }
    $log->warn("[Wkr $$] Finished but failed");
    return undef;
}

sub is_health_check {
    my $self    = shift;
    my $data    = shift;
    # no health checks yet

    return undef;
}

sub create_alertgroup {
    my $self    = shift;
    my $parser  = shift;
    my $data    = shift;
    my $method  = $self->create_method;

    my $agdata  = $parser->parse_message($data);
    my $created = $self->$method($data);
    return $created;
}

sub create_via_mongo {
    my $self    = shift;
    my $data    = shift;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Alertgroup');

    my @alertgroups = $col->api_create({
        request => {
            json => $data
        }
    });

    $self->scot_housekeeping(@alertgroups);
    return scalar(@alertgroups);
}

sub create_via_api {
    my $self    = shift;
    my $data    = shift;
    # TODO
}

sub scot_housekeeping {
    my $self    = shift;
    my @ag      = @_;
    my $env     = $self->env;
    my $mq      = $env->mq;
    
    foreach my $a (@ag) {
        $self->notify_flair_engine($a);
        $self->begin_history($a);
        $self->update_stats($a);
    }
}

sub notify_flair_engine {
    my $self        = shift;
    my $alertgroup  = shift;
    my $mq          = $self->env->mq;
    $mq->send("/topic/scot", {
        action  => "created",
        data    => {
            type    => "alertgroup",
            id      => $alertgroup->id,
            who     => "scot-alerts",
        }
    });
}

sub begin_history {
    my $self        = shift;
    my $alertgroup  = shift;
    my $mongo       = $self->env->mongo;

    $mongo->collection('History')->add_history_entry({
        who     => 'scot-alerts',
        what    => 'created alertgroup',
        when    => time(),
        target  => { id => $alertgroup->id, type => "alertgroup" },
    });
}

sub update_stats {
    my $self        = shift;
    my $alertgroup  = shift;
    my $mongo       = $self->env->mongo;
    my $now         = DateTime->now;
    my $col         = $mongo->collection('Stat');

    $col->increment($now, "alertgroup created", 1);
    $col->increment($now, "alerts created", $alertgroup->alert_count);
}

1;
