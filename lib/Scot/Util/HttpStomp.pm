package Scot::Util::HttpStomp;

use lib '../../../lib';
use strict;
use warnings;
use v5.18;

use Mojo::JSON qw/decode_json encode_json/;
use Data::GUID;
use Net::Stomp;
use Scot::Env;
use Data::Dumper;
use Try::Tiny;
use Try::Tiny::Retry;
use Mojo::UserAgent;
use XML::Twig;
use namespace::autoclean;

use Moose;
extends qw(Scot::Util);

has stomp_uri  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_stomp_host',
);

sub _build_stomp_uri {
    my $self    = shift;
    my $config  = $self->config;
    my $attr    = "stomp_uri";
    my $default = "https://localhost/scotaq/amq";
    return $self->get_config_value($attr,$default);
}

has topic => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_topic',
);

sub _build_topic {
    my $self    = shift;
    my $config  = $self->config;
    my $attr    = "topic";
    my $default = "topic://scot";
    return $self->get_config_value($attr,$default);
}

has client_guid => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    builder     => '_build_client_guid',
);

sub _build_client_guid {
    my $self    = shift;
    my $guid    = lc(Data::GUID->new->as_hex);
    $guid       =~ s/0x(.*)$/$1/;
    return $guid;
}

has timeout => (
    is          => 'ro',
    isa         => 'Int',   # seconds
    required    => 1,
    builder     => "_build_timeout",
);

sub _build_timeout {
    my $self    = shift;
    my $config  = $self->config;
    my $attr    = "timeout";
    my $default = 20;
    return $self->get_config_value($attr,$default);
}

has ua  => (
    is          => 'ro',
    isa         => 'Mojo::UserAgent',
    required    => 1,
    lazy        => 1,
    clearer     => 'clear_ua',
    builder     => '_build_ua',
);

sub _build_ua {
    my $self    = shift;
    my $uri     = $self->stomp_uri;
    my $topic   = $self->topic;
    my $ua      = Mojo::UserAgent->new;
    my $proxy   = $self->proxy;
    my $guid    = $self->client_guid;

    if ( defined $proxy ) {
        $ua->proxy->https($proxy);
    }

    my $iato = $self->timeout + 2;
    $ua->inactivity_timeout($iato);

    my $subscribe = {
        message     => 'chat',
        type        => 'listen',
        clientId    => $guid,
        destination => $topic,
    };
    my $tx  = $ua->post( $uri => { Accept => '*/*' } => form => $subscribe );

    # TODO: put in error checking

    return $ua;
}

sub get {
    my $self    = shift;
    my $coderef = shift; # code to call when response is received
    my $comet   = {
        clientId    => $self->client_guid,
        timeout     => $self->timeout * 1000,   # milliseconds
        d           => time() * 1000,
        json        => 'true',
        username    => $self->user,
    };
    my $tx = $self->ua->get($self->stomp_uri => {Accept => '*/*'} => form => $comet => $coderef);
    my $twig    = XML::Twig->new();
    $twig->parse($tx->res->body);
    my $root    = $twig->root;
    my $jsontxt = $root->text;
    my $json    = decode_json($jsontxt);
    return $json;
}

__PACKAGE__->meta->make_immutable;
1;        

__END__
=back

=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

