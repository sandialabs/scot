package Scot::Flair3::Worker;

use strict;
use warnings;
use utf8;
use lib '../../../lib';
use Moose;

use feature qw(signatures say);
no warnings qw(experimental::signatures);

use Scot::Flair3::Engine;
use Scot::Flair3::Stomp;
use Parallel::Prefork;
use Net::Stomp;
use JSON;
use Data::Dumper;
use Try::Tiny;

has workers => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 1,
);

has queue   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '/queue/flair'
);

has topic   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '/queue/topic'
);

has procmgr => (
    is          => 'ro',
    isa         => 'Parallel::Prefork',
    required    => 1,
    lazy        => 1,
    builder     => '_build_procmgr',
);

sub _build_procmgr ($self) {
    my $workers = $self->workers;
    return Parallel::Prefork->new({max_workers => $workers});
}

has stomp   => (
    is          => 'ro',
    isa         => 'Scot::Flair3::Stomp',
    required    => 1,
    lazy        => 1,
    builder     => '_build_stomp',
);

sub _build_stomp ($self) {
    return Scot::Flair3::Stomp->new();
}

has engine  => (
    is          => 'ro',
    isa         => 'Scot::Flair3::Engine',
    required    => 1,
    lazy        => 1,
    builder     => '_build_engine',
);

sub _build_engine ($self) {
    my $stomp   = $self->stomp;
    return Scot::Flair3::Engine->new(stomp => $stomp);
}

has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
);


sub run ($self, $ovr=undef) {
    my $pm  = $self->procmgr;

    my $stomp   = $self->stomp;
    my $engine  = $self->engine;
    my $log     = $engine->log;

    $log->info("Starting Flair Worker $$...");

    while ($pm->signal_received ne "TERM") {

        $stomp->subscribe($self->queue);
        $stomp->subscribe($self->topic);

        $pm->start(sub {
            while (1) {
                $log->info("Flair Worker $$ awaiting next frame...");
                my $frame = $stomp->receive();
                my $timer   = $engine->get_timer;
                next unless $frame;
                my $status = $self->process($frame, $ovr);
                if ( $status ) {
                    $log->info("acknowledging frame...");
                    $stomp->ack($frame);
                }
                else {
                    $log->info("nack frame...");
                    $stomp->nack($frame);
                }
                my $elapsed = &$timer;
                $log->info("TIME: total frame => $elapsed seconds");
                $log->info("Flair Worker $$ finishes ~~~~~~~~~~~~");
            }
        });

    }
    $pm->wait_all_children();
}

sub process ($self,$frame, $ovr=undef) {
    my $engine  = $self->engine;
    my $log     = $engine->log;

    $log->trace("Received frame ",{filter=>\&Dumper, value=>$frame});

    my $msg = $self->decode_frame($frame);
    if (! defined $msg) {
        $log->error("Failed to parse frame!");
        return undef;
    }
    $log->debug("Received ".$msg->{body}->{action}.
                "message for ".$msg->{body}->{data}->{type} .
                ":".$msg->{body}->{data}->{id}.
                " on ".$msg->{headers}->{destination});

    # allow for testing to send in an override function
    # to execute instead of main processing
    return &$ovr($msg) if ( defined $ovr );

    my $result = $engine->process_message($msg);
    return $result;
}

sub decode_frame ($self, $frame) {
    my $log     = $self->engine->log;
    my $headers = $frame->headers;
    my $json    = $frame->body;
    my $body    = $self->decode_body($json);
    if ( ! defined $body ) {
        $log->error("Failed to decode body from json: $json");
        return undef;
    }
    return {
        headers => $headers,
        body    => $body,
    };
}

sub decode_body ($self, $json) {
    my $body = decode_json($json);
    return $body;
}

sub decode_body_x ($self, $json) {
    my $log     = $self->engine->log;
    my $body    = try {
        my $d = decode_json($json);
        if ( ! defined $d->{action} ) {
            die "Missing Action Key";
        }
        if ( $d->{action} ne "created" and 
             $d->{action} ne "updated" and
             $d->{action} ne "test" ) {
            die "Invalid Action type: ".$d->{action};
        }
        if ( ! defined $d->{data}->{id} ) {
            die "Missing Object Integer Id in data block of message";
        }
        if ( $d->{data}->{id} !~ /^\d+$/ ) {
            die "Object Integer Id does not look like an integer: ".$d->{data}->{id};
        }
        if ( $d->{data}->{type} ) {
            if ( $d->{data}->{type} =~ /alertgroup/i and
                $d->{data}->{type} =~ /entry/i and
                $d->{data}->{type} =~ /remoteflair/i ) {
                die "Object Type is not a flairable type". $d->{data}->{type};
            }
        }
        else {
            die "Missing type from data block of message";
        }
        return $d;
    }
    catch {
        $log->error("Decoding AMQ Body for JSON Failed: $_");
        $log->debug("Body = ",{filter => \&Dumper, value => $json});
        return undef;
    };
    return $body;
}

__PACKAGE__->meta->make_immutable;
1;
