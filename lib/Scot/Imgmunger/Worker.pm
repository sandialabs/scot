package Scot::Imgmunger::Worker;

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
use Scot::Imgmunger::Processor;
use Module::Runtime qw(require_module);

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
    return Net::Stomp->new({
        hostname    => 'localhost',
        port        => 61613,
        ack         => 'client',
    });
}


has io      => (
    is      => 'ro',
    isa     => 'Scot::Imgmunger::Io',
    required=> 1,
    lazy    => 1,
    builder => '_build_io',
);


sub _build_io {
    my $self    = shift;
    my $env     = $self->env;
    return Scot::Imgmunger::Io->new(env => $env);
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
    default     => '/queue/imgmunger',
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


sub run {
    my $self    = shift;
    my $log     = $self->env->log;
    my $pm      = $self->procmgr;

    $log->info("Starting PreFork Imgmunger Worker");

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

    $stomp->connect();
    $stomp->subscribe({
        destination             => $queue,
        ack                     => 'client',
        'activemq.prefetchSize' => 1,
    });
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
        my $timer   = $env->get_timer("total_frame_process_time");
        my $data    = $self->decode_frame($frame);
        $self->process_message($data);
        &$timer;
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

    return undef if ($self->invalid_data($json));

    my $proc = Scot::Imgmunger::Processor->new(env => $self->env, scotio => $self->io);
    $proc->process_item($json);
}

sub invalid_data {
    my $self    = shift;
    my $json    = shift;
    my $action  = $json->{action};
    my $log     = $self->env->log;

    $self->env->log->trace({filter => \&Dumper, value => $json});

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

