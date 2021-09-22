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
use Scot::Flair::Regex;
use Scot::Flair::Extractor;
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
    return Net::Stomp->new({
        hostname    => 'localhost',
        port        => 61613,
        ack         => 'client',
    });
}

has regexes   => (
    is      => 'ro',
    isa     => 'Scot::Flair::Regex',
    required=> 1,
    lazy    => 1,
    builder => '_build_regexes',
);

has io      => (
    is      => 'ro',
    isa     => 'Scot::Flair::Io',
    required=> 1,
    lazy    => 1,
    builder => '_build_io',
);

has extractor => (
    is      => 'ro',
    isa     => 'Scot::Flair::Extractor',
    required=> 1,
    lazy    => 1,
    builder => '_build_extractor',
);

sub _build_regexes {
    my $self = shift;
    my $env = $self->env;
    return Scot::Flair::Regex->new(env => $env);
}

sub _build_io {
    my $self    = shift;
    my $env     = $self->env;
    return Scot::Flair::Io->new(env => $env);
}

sub _build_extractor {
    my $self    = shift;
    my $env     = $self->env;
    my $regex   = $self->regexes;
    return Scot::Flair::Extractor->new(env => $env, scot_regex => $regex);
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
    my $engine  = Scot::Flair::Engine->new(
        env => $env,
        regexes => $self->regexes,
        scotio  => $self->io,
        extractor => $self->extractor,
    );
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

#has timelog =>  (
#    is          => 'ro',
#    isa         => 'Log::Log4Perl::Logger',
#    required    => 1,
#    builder     => '_build_timelog',
#);

#sub _build_timelog {
#    my $self    = shift;
#    my $log     = Log::Log4perl->get_logger('timing');
#    my $layout  = Log::Log4perl::Layout::PatternLayout->new("%d [%P]  %12F{1}: %m%n");
#    my $append  = Log::Log4perl::Appender->new(
#        'Log::Log4perl::Appender::File',
#        name        => 'flair_time_log',
#        filename    => '/var/log/scot/times.log',
#        autoflush   => 1,
#    );
#    $append->layout($layout);
#    $log->add_appender($append);
#    $log->level('INFO');
#    return $log;
#}

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

    return undef if ($self->invalid_data($json));
    $self->engine->flair($json);
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

sub get_processor {
    my $self    = shift;
    my $json    = shift;
    my $type    = ucfirst(lc($json->{data}->{type}));
    my $log     = $self->env->log;

    my $class   = "Scot::Flair::Processor::$type";
    require_module($class);
    my $processor = $class->new(
        env         => $self->env,
        regexes     => $self->regexes,
        extractor   => $self->extractor,
        scotio      => $self->io,
    );
    return $processor;
}

1;

