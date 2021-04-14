package Scot::App::PFResponder;

use lib '../../../lib';
use strict;
use warnings;

use Net::Stomp;
use Parallel::Prefork;
use Data::Dumper;
use Try::Tiny;
use JSON;
use Scot::Env;
use Scot::App;
use Moose;
use DateTime;
extends 'Scot::App';

has stomp_host  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_stomp_host',
);

sub _build_stomp_host {
    my $self    = shift;
    my $attr    = "stomp_host";
    my $default = "localhost";
    my $envname = "scot_util_stomphost";
    return $self->get_config_value($attr, $default, $envname);
}
has stomp_port  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_build_stomp_port',
);

sub _build_stomp_port {
    my $self    = shift;
    my $attr    = "stomp_port";
    my $default = 61613;
    my $envname = "scot_util_stompport";
    return $self->get_config_value($attr, $default, $envname);
}

has max_workers => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_build_max_workers',
);

sub _build_max_workers {
    my $self    = shift;
    my $attr    = "max_workers";
    my $default = 3;
    my $envname = "scot_util_max_workers";
    return $self->get_config_value($attr, $default, $envname);
}

has mode    => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'message', # other supported mode is "test"
);

has procmgr => (
    is          => 'rw',
    isa         => 'Parallel::Prefork',
    required    => 1,
    lazy        => 1,
    builder     => '_build_procmgr',
);

sub _build_procmgr {
    my $self    = shift;
    my $workers = $self->max_workers;
    return Parallel::Prefork->new({ max_workers => $workers });
}

has stomp   => (
    is          => 'rw',
    isa         => 'Net::Stomp',
    required    => 1,
    lazy        => 1,
    builder     => '_build_stomp',
);

sub _build_stomp {
    my $self    = shift;
    my $stomp   = Net::Stomp->new({
        hostname    => $self->stomp_host,
        port        => $self->stomp_port,
        ack         => 'client',
    });
    return $stomp;
}

has queue   => (
    is      => 'rw',
    isa     => 'Str',
    required    => 1,
    builder     => '_build_queue',
);

sub _build_queue {
    my $self    = shift;
    my $attr    = "queue";
    my $default = "/queue/scot";
    my $envname = "scot_queue";
    return $self->get_config_value($attr, $default, $envname);
}

has name    => (
    is      => 'rw',
    isa     => 'Str',
    required    => 1,
    default => 'pfrespond',
);

sub get_human_time {
    my $self    = shift;
    my $dt      = DateTime->now();
    return $dt->ymd." ".$dt->hms;
}

sub run {
    my $self    = shift;
    my $log     = $self->log;
    my $stomp   = $self->stomp;
    my $pm      = $self->procmgr;
    my $queue   = $self->queue;
    my $name    = $self->name;

    $log->debug("Starting Responder $name daemon");


    while ( $pm->signal_received ne 'TERM' ) {
        $pm->start(sub {
            $log->debug("Spawned $name responder with pid $$ to listen to $queue");
            $stomp->connect();
            $stomp->subscribe({
                destination => $self->queue,
                ack         => 'client',
                'activemq.prefetchSize' => 1,
            });
            while (1) {
                $log->debug("waiting for frame");
                my $frame;
                try {
                    $frame   = $stomp->receive_frame;
                    $log->debug("Recv Frame: ",{filter=>\&Dumper, value => $frame});
                    next unless ( defined $frame );

                    my $headers = $frame->headers;
                    my $body    = $frame->body;
                    my $href    = decode_json $body;
                    my $status  = $self->process_message($pm, $href);

                    $log->debug("acknowledging amq frame");
                    $stomp->ack({frame => $frame});
                }
                catch {
                    $log->error("^^^ Error Caught: $_");
                    $log->error("^^^ ",{filter=>\&Dumper,value=>$frame});
                    $log->debug("NOT acknowledging amq frame");
                    $stomp->nack({frame => $frame});
                    die "ERROR: $_";
                };
            }
        });
    }
    $pm->wait_all_children();
}
1;
