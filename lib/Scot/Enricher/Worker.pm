package Scot::Enricher::Worker;

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
use Scot::Enricher::Processor;
use Scot::Enricher::Io;
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
    isa     => 'Scot::Enricher::Io',
    required=> 1,
    lazy    => 1,
    builder => '_build_io',
);


sub _build_io {
    my $self    = shift;
    my $env     = $self->env;
    return Scot::Enricher::Io->new(env => $env);
}

has enrichments => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_enrichments',
);

sub _build_enrichments {
    my $self                = shift;
    my $enrichment_configs  = $self->env->enrichers;
    my @enrichments         = ();
    my $log                 = $self->env->log;

    $log->debug("building enrichments");
    $log->trace({filter=>\&Dumper, value => $enrichment_configs});

    foreach my $enrichment_name (sort keys %$enrichment_configs) {
        my $ename   = ucfirst($enrichment_name);
        my $class   = "Scot::Enricher::Enrichment::$ename";
        $log->debug("Building enrichment $ename");
        my $config  = $enrichment_configs->{$enrichment_name};
        $log->debug("Config is ",{filter=>\&Dumper, value=>$config});
        require_module($class);
        my $enrichment  = $class->new(
            env     => $self->env,
            conf    => $config,
        );
        push @enrichments, $enrichment;
    }
    return \@enrichments;
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
    default     => '/queue/enricher',
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
        $stomp->ack({frame => $frame});
    }
    catch {
        $log->error("!!!! ");
        $log->error("!!!! Error Caught: $_ ");
        $log->error("!!!! Frame = ",{filter=>\&Dumper, value=>$frame});
        $log->error("!!!! ");
        # die "Error: $_";
        # $stomp->nack({frame => $frame});
        # when we have an error, clone data of message, add error field/count
        $self->handle_error($frame, $_);
    };
}

sub handle_error {
    my $self    = shift;
    my $frame   = shift;
    my $error   = shift;
    my $log     = $self->env->log;
    my $data    = $self->decode_frame($frame);
    my $stomp   = $self->stomp;
    $data->{body}->{errors}->{$error}++;

    if ($data->{body}->{errors}->{$error} > 5) {
        $log->error("--------");
        $log->error(" Error: $error ");
        $log->error(" exceeded retry threshold.");
        $log->error(" Frame = ",{filter=>\&Dumper, value=>$frame});
        $log->error("--------");
        $stomp->ack({frame => $frame});
        return;
    }
    $stomp->ack({frame => $frame});
    $log->error("Resubmitting to ".$self->queue);
    $self->io->send_mq($self->queue, $data->{body});
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

    my $proc = Scot::Enricher::Processor->new(
        env         => $self->env, 
        scotio      => $self->io, 
        enrichments => $self->enrichments,
    );
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
        $log->error("Invalid action for enricher.  Dropping message");
        return 1;
    }

    my $type        = $json->{data}->{type};
    my @valid_types = (qw(entity));
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

