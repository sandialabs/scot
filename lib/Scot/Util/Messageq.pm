package Scot::Util::Messageq;

use lib '../../../lib';
use strict;
use warnings;
use v5.18;

use Moose;
use Mojo::JSON qw/decode_json encode_json/;
use Data::GUID;
use Net::Stomp;
use Scot::Env;
use Data::Dumper;
use Try::Tiny;
use Try::Tiny::Retry;
use namespace::autoclean;

has stomp   => (
    is      => 'ro',
    isa     => 'Maybe[Net::Stomp]',
    required    => 1,
    lazy    => 1,
    builder => '_build_stomp',
);

has env     => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required    => 1,
    default => sub { Scot::Env->instance },
);

has stomp_host  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'localhost',
);

has stomp_port  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 61613,
);

sub _build_stomp {
    my $self    = shift;
    my $log     = $self->env->log;
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
    my $dest    = shift;
    my $href    = shift;
    my $log     = $self->env->log;
    my $stomp   = $self->stomp;

    my $savelevel   = $log->level();
    $log->level(Log::Log4perl::Level::to_priority('WARN'));

    my $guid    = Data::GUID->new;
    my $gstring = $guid->as_string;
    $href->{guid}   = $gstring;
    my $body    = encode_json($href);

    #if ( $self->is_connected ) {
        try {
            $stomp->send({
                destination => "/".$dest,
                body        => $body,
                'amq-msg-type'  => 'text',
            });
        }
        catch {
            $log->error("Error sending to STOMP message: $_");
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

