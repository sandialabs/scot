package Scot::Util::ActiveMQ;

use lib '../../../lib';
use lib '../lib';
use strict;
use warnings;
use v5.10;

use Data::Dumper;
use JSON;
use Data::GUID;
use Moose;
use Net::STOMP::Client;
use namespace::autoclean;

=head1  NAME

Scot::Util::ActiveMQ

=head1 DESCRIPTION

Utility Module to do the grunt work of connection to ActiveMQ
and provide a "send" method to send messages to ActiveMQ

=head1 SYNOPSIS

my $amq = Scot::Util::ActiveMQ->new({
    config  => $config_href,
    'log'   => $logger,
});

Often this is done for you though by the Scot.pm (web access)
or the Tasker.pm (command line tools) and can be accessed by
my $amq = $scot_app->activemq 
or $amq = $tasker->activemq.

=head1 Attributes

=over 4

=item C<config>

Hash reference to the digested Scot config file

=cut

has config      => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

=item C<log>

the Log::Log4Perl logger object

=cut

has 'log'       => (
    is          => 'ro',
    isa         => 'Object',
    required    => 1,
);

=item C<stomp_handle>

This holds the Net::STOMP::Client refrence that is created for you
from the settings based in the scot.json config file.

=cut

has stomp_handle => (
    is          => 'ro',
    isa         => 'Maybe[Net::STOMP::Client]',
    required    => 1,
    lazy        => 1,
    builder     => '_build_handle',
);

=back

=head1 Methods

=over 4

=item C<_build_handle>

method that sets the stomp_handle attribute.  

=cut

sub _build_handle {
    my $self        = shift;
    my $log         = $self->log;
    my $config      = $self->config;

    my $amq = undef;

    # need to move this into config and replace hard coding
    eval {
        $amq    = Net::STOMP::Client->new(
            host    => "127.0.0.1",
            port    => 61613,
        );
        $amq->connect();
    };
    if ( $@ ) {
        $log->error("Error Connecting to AMQ");
        $log->error($@);
    }
    return $amq;
}

=item C<is_connected>

returns true if you are connected to the activemq server.

=cut

sub is_connected {
    my $self    = shift;
    my $log     = $self->log;
    my $amq     = $self->stomp_handle;

    eval {
        $amq->connect();
    };
    my $retries = 3;
    while ($@ and $retries >0) {
        $retries--;
        $log->error("Error Connecting to ActiveMQ");
        $log->error($@);
        eval {
            $amq->connect();
        };
    }
    return 1;
}

=item C<send>

    send takes the following parameters
        $dest       the destination.  value passed in is prepended with /topic
        $href       the message to send that look like below:
        
        my $message_href    = {
            type        => $href->{target_type},
            id          => $href->{target_id},
            action      => $href->{action},
            is_task     => $href->{is_task,
            view_count  => $href->{view_count},
        };

=cut

sub send {
    my $self    = shift;
    my $dest    = shift;
    my $href    = shift;
    my $guid    = Data::GUID->new;
    my $log     = $self->log;

    $log->debug("Attempting to send AMQ message");

    my $guidstr = $guid->as_string;
    $href->{guid} = $guidstr;
    my $json    = to_json($href);
    my $amq     = $self->stomp_handle;

    $log->debug("Sending AMQ message to /topic/$dest");
    $log->debug(Dumper($json));


    eval {
        $amq->send(
            destination     => "/topic/".$dest,
            body            => $json,
            'amq-msg-type'  => "text",
        );
    };
    if ($@) {
        $log->error("Error Sending to ActiveMQ: ".$@);
    }
}

1;        
__END__
=back

=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

