package Scot::Client::Messageq;

use lib '../../../lib';
use strict;
use warnings;
use Moose;
use feature 'signatures';
no warnings qw(experimental::signatures);

use Mojo::JSON qw(decode_json encode_json);
use Data::GUID;
use Net::Stomp;
use Sys::Hostname;
use Data::Dumper;
use Try::Tiny;
use Try::Tiny::Retry;
use Log::Log4perl qw(get_logger);
use namespace::autoclean;

has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    lazy        => 1,
    required    => 1,
    default     => sub { get_logger('Scot') },
);

has config => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    default     => sub {{
        host    => 'localhost',
        port    => 61613,
    }},
);

has stomp   => (
    is          => 'ro',
    isa         => 'Maybe[Net::Stomp]',
    required    => 1,
    lazy        => 1,
    builder     => '_build_stomp',
    clearer     => '_clear_stomp',
);

sub _build_stomp ($self) {
    my $stomp;
    try {
        $stomp = Net::Stomp->new({
            hostname    => $self->config->{host},
            port        => $self->config->{port},
            logger      => $self->log,
        });
    }
    catch {
        $self->log->error("Error creating STOMP client: $_");
    };

    try {
        $stomp->connect();
    }
    catch {
        $self->log->error("Error connecting: $_");
    };

    return $stomp;
}

sub send ($self, $destination, $data) {

    my $stomp = $self->stomp;
    return unless ($stomp);

    my $pid     = $$;
    my $host    = hostname;
    my $guid    = Data::GUID->new;
    my $gstring = $guid->as_string;
    my $body    = encode_json($data);
    my $length  = length($body);
    my $rcvframe;

    try {
        $stomp->send_transactional({
            destination         => $destination,
            body                => $body,
            'amq-msg-type'      => 'text',
            'content-length'    => $length,
            persistent          => 'true',
        }, $rcvframe);
    }
    catch {
        $self->log->error("Error sending Message: $_. ".$rcvframe->as_string);
    };
}

__PACKAGE__->meta->make_immutable;
1;

