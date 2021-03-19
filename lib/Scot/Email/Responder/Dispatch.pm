package Scot::Email::Responder::Event;

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
    default => 'Dispatch',
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

sub is_health_check {
    my $self    = shift;
    my $data    = shift;
    # there are no health checks for this yet
    return undef;
}

sub process_message {
    my $self    = shift;
    my $pm      = shift;
    my $href    = shift;
    my $data    = $href->{email};
    my $log     = $self->env->log;

    $log->debug("[Wkr $$] Processing Dispatch");

    if ( $self->is_health_check($data) ) {
        $log->warn("[Wkr $$] Finished: Skipping health checks");
        return 1;
    }

    PARSE:
    foreach my $parser (@{$self->parsers}) {

        if ( ! $parser->will_parse($data) ) {
            $log->warn(ref($parser)." will not parse this data");
            next PARSE;
        }

        if ( $self->create_dispatch($parser, $data) ) {
            $log->debug("[Wkr $$] Finished: Created a dispatch");
            return 1;
        }

        $log->error("Failed to create dispatch from ",
                    {filter => \&Dumper, value => $data});
    }
    $log->warn("[Wkr $$] Finished but failed");
    return undef;
}

sub create_dispatch {
    my $self    = shift;
    my $data    = shift;
    my $method  = $self->create_method;

    return $self->$method($data);
}

sub create_via_mongo {
    my $self    = shift;
    my $data    = shift;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Dispatch');

    my $dispatch   = $col->api_create({
        request => {
            json    => $data,
        }
    });

    if (defined $dispatch and ref($dispatch) eq "Scot::Model::Dispatch" ) {
        $self->scot_housekeeping($dispatch);
        return 1;
    }
    return undef;
}

sub create_via_api {
    my $self    = shift;
    my $data    = shift;
    # TODO
}

sub scot_housekeeping {
    my $self        = shift;
    my $dispatch    = shift;
    $self->notify_flair_engine($dispatch);
    $self->being_history($dispatch);
    $self->update_stats($dispatch);
}

sub notify_flair_engine {
    my $self        = shift;
    my $dispatch  = shift;
    my $mq          = $self->env->mq;
    $mq->send("/topic/scot", {
        action  => "created",
        data    => {
            type    => "dispatch",
            id      => $dispatch->id,
            who     => "scot-alerts",
        }
    });
}

sub begin_history {
    my $self        = shift;
    my $dispatch  = shift;
    my $mongo       = $self->env->mongo;

    $mongo->collection('History')->add_history_entry({
        who     => 'scot-alerts',
        what    => 'created dispatch',
        when    => time(),
        target  => { id => $dispatch->id, type => "dispatch" },
    });
}

sub update_stats {
    my $self        = shift;
    my $alertgroup  = shift;
    my $mongo       = $self->env->mongo;
    my $now         = DateTime->now;
    my $col         = $mongo->collection('Stat');

    $col->increment($now, "dispatch created", 1);
}

1;
