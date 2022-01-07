package Scot::Flair3::Stomp;

use lib '../../../lib';
use strict;
use warnings;
use Moose;

use feature qw(signatures say);
no warnings qw(experimental::signatures);
use Try::Tiny;
use Net::Stomp;
use Sys::Hostname;
use Data::GUID;
use JSON;
use Data::Dumper;

# config {
#   hostname => 
#   port => 
#   ack => 
#   ssl => 1
#   ssl_options =>{}
#   logger => 'Log::Any

has stomp_config => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { {
        hostname    => 'localhost',
        port        => 61613,
        ack         => 'client',
    }},
);

has receiver  => (
    is      => 'ro',
    isa     => 'Net::Stomp',
    required=> 1,
    lazy    => 1,
    builder => '_build_receiver',
    clearer => '_clear_receiver',
);

sub _build_receiver ($self) {
    my $config      = $self->stomp_config;
    my $receiver    = Net::Stomp->new($config);
    my $frame       = $receiver->connect();
    if ( $frame->command ne "CONNECTED" ) {
        die "Receiver FAILED TO CONNECT!";
    }
    return $receiver;
}

has sender  => (
    is      => 'ro',
    isa     => 'Net::Stomp',
    required=> 1,
    lazy    => 1,
    builder => '_build_sender',
    clearer => '_clear_sender',
);

sub _build_sender ($self) {
    my $config  = $self->stomp_config;
    my $sender  = Net::Stomp->new($config);
    my $frame   = $sender->connect();
    if ( $frame->command ne "CONNECTED" ) {
        die "Sender FAILED TO CONNECT!";
    }
    return $sender;
}

sub subscribe ($self, $dest) {
    my $receiver    = $self->receiver;
    $receiver->subscribe({
        destination             => $dest,
        ack                     => 'client',
        'activemq.prefetchSize' => 1,
    });
    say "subscribed to $dest";
}

# docs for Net::Stomp say not to send to a $dest
# that you are already subscribed to.  So we send
# on the second connection $sender
sub send ($self, $dest, $msg) {
    my $sender  = $self->sender;
    my $guid    = Data::GUID->new;
    my $gstring = $guid->as_string;
    
    $msg->{pid}         = $$;
    $msg->{hostname}    = hostname;
    $msg->{guid}        = $gstring;

    my $body    = $self->encode_body($msg);
    my $length  = length($body);
    my $rcvframe;
    my $framedata   = {
        destination         => $dest,
        body                => $body,
        'content-length'    => $length,
        'amq-msg-type'      => 'text',
        persistent          => 'true',
    };

    my $success = $sender->send_transactional($framedata, $rcvframe);
    if (! $success) {
        warn $rcvframe->as_string;
    }
}

sub receive ($self) {
    my $stomp   = $self->receiver;
    my $frame   = $stomp->receive_frame;
    return $frame;
}

sub ack ($self, $frame) {
    my $stomp   = $self->receiver;
    $stomp->ack({ frame => $frame });
}

sub nack ($self, $frame) {
    my $stomp   = $self->receiver;
    $stomp->nack({ frame => $frame });
}

sub encode_body ($self, $msg) {
    return try {
        encode_json($msg);
    }
    catch {
        warn "Error encoding Message into JSON: $_";
        return undef;
    };
}

__PACKAGE__->meta->make_immutable;

1;
