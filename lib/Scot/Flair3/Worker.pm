package Scot::Flair::Worker;

use strict;
use warnings;
use utf8;
use lib '../../../lib';
use Moose;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;
use Try::Tiny;
use Parallel::Prefork;
use Scot::Flair3::Io;
use Scot::Flair3::Engine;
use namespace::autoclean;

# only required parameter is workertype
# core | udef

has workertype => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
    default => 'core', # or udef
);

has io  => (
    is       => 'ro',
    isa      => 'Scot::Flair3::Io',
    required => 1,
    builder  => '_build_io',
);

sub _build_io ($self) {
    return Scot::Flair3::Io->new;
}

has engine  => (
    is       => 'ro',
    isa      => 'Scot::Flair3::Engine',
    required => 1,
    lazy     => 1,
    builder  => '_build_engine',
);

sub _build_engine ($self) {
    return Scot::Flair3::Engine->new(
        selected_regex_set  => $self->workertype
    );
}

has imgmunger   => (
    is          => 'ro',
    isa         => 'Scot::Flair3::Imgmunger',
    required    => 1,
    builder     => '_build_imgmunger',
);

sub _build_imgmunger ($self) {
    return Scot::Flair3::Imgmunger->new;
}

=item workers

maximum number of workers to prefork

=cut

has workers => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    default  => 5,
);

=item queue

Queue to listen to for new things to flair

=cut

has queue   => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    builder  => '_build_queue',
);

sub _build_queue ($self) {
    my $wt  = $self->workertype;
    if ( $wt eq "core" ) {
        return '/queue/flair';
    }
    return '/queue/udflair';
}

=item topic

Topic to listen to for broadcast instructions to all workers
typically, a call to refresh regexes or similar

=cut

has topic   => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => '/topic/flair',
);

has procmgr     => (
    is       => 'ro',
    isa      => 'Parallel::Prefork',
    required => 1,
    lazy     => 1,
    builder  => '_build_procmgr',
);

sub _build_procmgr ($self) {
    my $count   = $self->workers;
    return Parallel::Prefork->new({max_workers => $count});
}

sub run ($self) {
    my $io  = $self->io;
    my $log = $io->log;
    my $pm  = $self->procmgr;
    my $queue = $self->queue;
    my $topic = $self->topic;

    $log->info("Starting PreFork Flair Worker");
    $io->clear_worker_status;

    while ($pm->signal_received ne "TERM") {

        $pm->start(sub {
            $log->debug("[$$] Spawned $queue worker");
            $io->connect_to_amq($queue, $topic);
            while (1) {
                $self->process_frame;
            }
        });

    }
    $pm->wait_all_children();
}

sub process_frame ($self) {
    my $io      = $self->io;
    my $log     = $io->log;

    my $frame   = $io->receive_frame;
    my $timer   = $io->get_timer('frame_processing_time');
    
    if (! defined $frame) {
        $log->error("!!! Undefined Frame !!! Skipping...");
        $io->ack_frame($frame); # remove it from queue
    }

    my $message = $io->decode_frame($frame);

    if (! defined $message) {
        $log->error("!!! Frame Decode Error. skipping...");
        $io->ack_frame($frame);
    }

    if ($self->process_message($message)) {
        my $elapsed = &$timer;
        $log->info("=== $elapsed seconds frame processing time ===");
        $io->ack_frame($frame);
    }
    else {
        $log->error("!!! Message Processing Error !!!");
        $io->nack_frame($frame);
    }
}

sub process_message ($self, $message) {
    
    my $json    = $message->{body};
    my $dest    = $message->{headers}->{destination};

    if ( $dest eq $self->topic ) {
        return $self->process_topic_message($message);
    }
    if ( $self->invalid_message_json($json) ) {
        return undef;
    }
    return $self->engine->flair($json);
}

sub invalid_message_json ($self, $json) {
    my $log     = $self->io->log;
    my $action  = $json->{action};
    
    if ( ! defined $action ) {
        $log->error("Missing Action Key!");
        $log->debug("JSON = ",{filter => \&Dumper, value => $json});
        return 1;
    }
    if ( $action ne "created" and $action ne "updated" ) {
        $log->error("Invalid action type: $action.");
        return 1;
    }
    my $id  = $json->{data}->{id};
    if ( ! defined $id ) {
        $log->error("Missing integer ID in message!");
        $log->debug("JSON = ",{filter => \&Dumper, value => $json});
        return 1;
    }
    if ( $id !~ /^\d+$/ ) {
        $log->error("Invalid id: $id, must be an integer");
        return 1;
    }
    return undef;
}



__PACKAGE__->meta->make_immutable;
    
1;
