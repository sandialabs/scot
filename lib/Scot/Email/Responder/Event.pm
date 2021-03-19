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
    default => 'Event',
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
        Scot::Email::Parser::Event
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
    # no health checks yet
    return undef;
}

sub process_message {
    my $self    = shift;
    my $pm      = shift;
    my $href    = shift;
    my $data    = $href->{email};
    my $log     = $self->env->log;

    $log->debug("[Wkr $$] Processing Event");

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

        if ( $self->create_event($parser, $data) ) {
            $log->debug("[Wkr $$] Finished: Created event");
            return 1;
        }

        $log->error("Failed to create event from ",
                    { filter => \&Dumper, value => $data });
    }
    $log->warn("[Wkr $$] Finished but failed");
    return undef;
}


sub create_event {
    my $self    = shift;
    my $data    = shift;
    my $method  = $self->create_method;

    return $self->$method($data);
}

sub create_via_mongo {
    my $self    = shift;
    my $data    = shift;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Event');

    my $event   = $col->api_create({
        request => {
            json    => $data,
        }
    });

    if (defined $event and ref($event) eq "Scot::Model::Event" ) {
        $self->scot_housekeeping($event);
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
    my $event    = shift;
    $self->notify_flair_engine($event);
    $self->being_history($event);
    $self->update_stats($event);
}

sub notify_flair_engine {
    my $self        = shift;
    my $event  = shift;
    my $mq          = $self->env->mq;
    $mq->send("/topic/scot", {
        action  => "created",
        data    => {
            type    => "event",
            id      => $event->id,
            who     => "scot-alerts",
        }
    });
}

sub begin_history {
    my $self        = shift;
    my $event  = shift;
    my $mongo       = $self->env->mongo;

    $mongo->collection('History')->add_history_entry({
        who     => 'scot-alerts',
        what    => 'created event',
        when    => time(),
        target  => { id => $event->id, type => "event" },
    });
}

sub update_stats {
    my $self        = shift;
    my $alertgroup  = shift;
    my $mongo       = $self->env->mongo;
    my $now         = DateTime->now;
    my $col         = $mongo->collection('Stat');

    $col->increment($now, "event created", 1);
}
1;
