package Scot::Util::Messageq;

use lib '../../../lib';
use strict;
use warnings;
use v5.18;

use Mojo::JSON qw/decode_json encode_json/;
use Data::GUID;
use Net::Stomp;
use Sys::Hostname;
use Scot::Env;
use Data::Dumper;
use Sys::Hostname;
use Try::Tiny;
use Try::Tiny::Retry;
use namespace::autoclean;

use Moose;
extends qw(Scot::Util);

has stomp_host  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_stomp_host',
);

sub _build_stomp_host {
    my $self    = shift;
    my $config  = $self->config;
    my $attr    = "stomp_host";
    my $default = "localhost";
    return $self->get_config_value($attr,$default);
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
    my $config  = $self->config;
    my $attr    = "stomp_port";
    my $default = 61613;
    return $self->get_config_value($attr,$default);
}

has stomp   => (
    is      => 'ro',
    isa     => 'Maybe[Net::Stomp]',
    required    => 1,
    lazy    => 1,
    builder => '_build_stomp',
    clearer => '_clear_stomp',
);

sub _build_stomp {
    my $self    = shift;
    my $log     = $self->log;
    my $stomp;

    $log->debug("Creating STOMP client");

    try {
        $stomp  = Net::Stomp->new({
            hostname    => $self->stomp_host,
            port        => $self->stomp_port,   
            # TODO: make sure queue is SSL
            # ssl   => 1,
            # ssl_options => { },
            logger  => $log,
        });
        $stomp->connect();
    }
    catch {
        $log->error("Error creating STOMP client: $_");
        return undef;
    };

    try {
        $stomp->connect();
    }
    catch {
        $log->error("Error connecting: $_");
    }
    return $stomp;
}


sub send {
    my $self    = shift;
    my $dest    = shift; # /queue/* or /topic/*
    my $href    = shift;
    my $log     = $self->log;
    my $stomp   = $self->stomp;

    unless ($stomp) {
        $self->_clear_stomp
    }

    unless ($stomp) {
        $log->error("not able to send STOMP message!",{filter=>\&Dumper, value=> $href});
        return;
    }
    
    $href->{pid}        = $$;
    $href->{hostname}   = hostname;

    my $savelevel   = $log->level();
    $log->level(Log::Log4perl::Level::to_priority('TRACE'));

    $log->trace("Sending STOMP message: ",{filter=>\&Dumper, value=>$href});

    my $guid        = Data::GUID->new;
    my $gstring     = $guid->as_string;
    $href->{guid}   = $gstring;
    my $body        = encode_json($href);
    my $length      = length($body);

    my $rcvframe;
    #if ( $self->is_connected ) {
        try {
            $log->debug("inside try");
            $stomp->send_transactional({
                destination         => $dest,
                body                => $body,
                'amq-msg-type'      => 'text',
                'content-length'    => $length,
                persistent          => 'true',
            }, $rcvframe);
            $log->debug("after send_transactional");
        }
        catch {
            $log->error("Error sending to STOMP message: $_");
            $log->error($rcvframe->as_string);
        };
    #}
    $log->level($savelevel);
    # $stomp->disconnect();
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

