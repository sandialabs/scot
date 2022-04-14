package Scot::Flair::Worker;

use strict;
use warnings;
use utf8;
use lib '../../../lib';

use Data::Dumper;
use Try::Tiny;
use Parallel::Prefork;
use Net::Stomp;
use JSON;
use DateTime;
use Scot::Env;
use Scot::Flair::Io;
use Scot::Flair::Engine;
use Module::Runtime qw(require_module);
use namespace::autoclean;

use Moose;

has env => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required=> 1,
);

has stomp   => (
    is      => 'rw',
    isa     => 'Net::Stomp',
    required=> 1,
    lazy    => 1,
    builder => '_build_stomp',
);

sub _build_stomp {
    my $self    = shift;
    my $env     = $self->env;
    my $cfg     = {
        hostname    => 'localhost',
        port        => 61613,
        ack         => 'client',
    };
    return Net::Stomp->new($cfg);
}

has engine  => (
    is      => 'ro',
    isa     => 'Scot::Flair::Engine',
    required => 1,
    lazy    => 1,
    builder => '_build_engine',
);

sub _build_engine {
    my $self    = shift;
    my $env     = $self->env;
    my $engine  = Scot::Flair::Engine->new(env => $env);
    return $engine;
}

has workers => (
    is      => 'ro',
    isa     => 'Int',
    required=> 1,
    lazy    => 1,
    builder => '_build_workers',
);

sub _build_workers {
    my $self    = shift;
    my $env     = shift;
    my $workers = $self->env->max_workers // 5;
    return $workers;
}

has queue   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '/queue/flair',
);

has topic   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '/topic/flair',
);

has procmgr => (
    is          => 'ro',
    isa         => 'Parallel::Prefork',
    required    => 1,
    lazy        => 1,
    builder     => '_build_procmgr',
);

sub _build_procmgr {
    my $self    = shift;
    my $workers = $self->workers;
    return Parallel::Prefork->new({max_workers => $workers});
}

has io  => (
    is       => 'ro',
    isa      => 'Scot::Flair::Io',
    required => 1,
    lazy     => 1,
    builder  => '_build_scotio',
);
sub _build_scotio {
    my $self    = shift;
    my $env     = $self->env;
    return Scot::Flair::Io->new(env => $env);
}

sub run {
    my $self    = shift;
    my $log     = $self->env->log;
    my $pm      = $self->procmgr;

    $log->info("Starting PreFork Flair Worker");
    $self->io->clear_worker_status;

    while ($pm->signal_received ne "TERM") {

        $pm->start(sub {
            $log->debug("[$$] Spawned Worker");
            $self->connect_to_queue;
            while (1) {
                $self->process_frame;
            }
        });

    }
    $pm->wait_all_children();
}

sub connect_to_queue {
    my $self    = shift;
    my $stomp   = $self->stomp;
    my $queue   = $self->queue;
    my $topic   = $self->topic;
    my $log     = $self->env->log;

    $stomp->connect();
    $stomp->subscribe({
        destination             => $queue,
        ack                     => 'client',
        'activemq.prefetchSize' => 1,
    });
    $log->debug("subscribed to $queue");
    $stomp->subscribe({
        destination             => $topic,
        ack                     => 'client',
        'activemq.prefetchSize' => 1,
    });
    $log->debug("subscribed to $topic");
}

sub process_frame {
    my $self    = shift;
    my $stomp   = $self->stomp;
    my $env     = $self->env;
    my $log     = $env->log;
    my $frame;

    try {
        $frame      = $stomp->receive_frame;
        next unless (defined $frame);
        $log->info("========= Recieved Frame ============");
        my $timer   = $env->get_timer("total_frame_process_time");
        my $data    = $self->decode_frame($frame);
        $self->process_message($data);
        my $elapsed = &$timer;
        $log->info("========= $elapsed secs Frame process time =======");
        $stomp->ack({frame => $frame});
        $log->info("========= Acknowledged Frame ============");

        $log->info("TIME == $elapsed secs :: Frame Time");
    }
    catch {
        $stomp->nack({frame => $frame});
        $log->error("!!!! Error Caught: $_ ");
        $log->error("!!!! Frame = ",{filter=>\&Dumper, value=>$frame});
        die "Error: $_";
    };
}

sub decode_frame {
    my $self    = shift;
    my $frame   = shift;
    my $body    = $frame->body;
    return {
        headers => $frame->headers,
        body    => decode_json $body,
    };
}

sub process_message {
    my $self    = shift;
    my $data    = shift;
    my $json    = $data->{body};
    my $log     = $self->env->log;

    if ( $data->{headers}->{destination} eq $self->topic ) {
        $self->process_topic_message($data);
        return;
    }
    return undef if ($self->invalid_data($json));
    $self->engine->flair($json);
}

sub process_topic_message {
    my $self    = shift;
    my $data    = shift;

    my $body    = $data->{body};
    my $retypes = $body->{reload};

    $self->engine->reload_regexes($retypes);
    $self->env->log->debug("processed topic message");

}

sub invalid_data {
    my $self    = shift;
    my $json    = shift;
    my $action  = $json->{action};
    my $log     = $self->env->log;

    $self->env->log->debug({filter => \&Dumper, value => $json});

    if (! defined $action ) {
        $log->error("Missing Action key");
        return 1;
    }

    if ( $action ne "created" and $action ne "updated" ) {
        $log->error("Invalid action for flair.  Dropping message");
        return 1;
    }

    my $type        = $json->{data}->{type};
    my @valid_types = (qw(alertgroup entry remoteflair));
    if ( ! grep {/$type/} @valid_types ) {
        $log->error("Invalid type $type in message.");
        return 1;
    }

    my $id          = $json->{data}->{id};
    if ( ! defined $id or $id !~ /^\d+$/ ) {
        $log->error("Invalid id: $id in message.");
        return 1;
    }
    return undef;
}

1;

