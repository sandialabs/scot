package Scot::Util::Activemq;

use lib '../../../lib';
use strict;
use warnings;
use v5.18;

use Moose 2;
use MooseX::AttributeShortcuts;

use Mojo::JSON qw/decode_json encode_json/;
use Data::GUID;
use Net::STOMP::Client;
use Scot::Env;
use Data::Dumper;
use Type::Params qw/compile/;
use Types::Standard qw/slurpy :types/;
use namespace::autoclean;

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

has 'env'   => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required    => 1,
    default => sub { Scot::Env->instance },
);

=back

=head1 Methods

=over 4

=item C<_build_handle>

method that sets the stomp_handle attribute.  

=cut

sub _build_handle {
    my $self        = shift;
    my $log         = $self->env->log;

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
    my $log     = $self->env->log;
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
    my $href    = shift;
    my $log     = $self->env->log;

    my $dest    = $href->{dest};
    delete $href->{dest};

    my $guid    = Data::GUID->new;
    my $guidstr = $guid->as_string;
    $href->{guid} = $guidstr;
    my $json    = encode_json($href);
    my $amq     = $self->stomp_handle;

    $log->trace("Sending AMQ message to /topic/$dest");
    $log->trace(Dumper($json));


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

sub send_amq_notification {
    my $self    = shift;
    my $type    = shift; # creation, update, delete
    my $obj     = shift;
    my $user;
    if ($obj->meta->does_role("Scot::Role::Permission") || 
        $obj->meta->does_role("Scot::Role::Owner")) {
       $user = $obj->owner;
    }
    else {
        $user = '';
    }

    my $thing   = $obj->get_collection_name;

    my $href    = {
        dest    => "/topic/". $thing,
        id      => $obj->id,
        type    => $type,
        user    => $user,
    };

    if ( $obj->meta->does_role("Scot::Role::Targets") ) {
        $href->{targets}    = $obj->targets;
    }
    $self->send($href);
}

sub subscribe {
    my $self    = shift;
    my $dest    = shift;
    my $id      = shift;
    $self->stomp_handle->subscribe(
        destination     => "/topic/".$dest,
        id              => $id,
        ack             => "client",
    );
}

sub get_message {
    my $self    = shift;
    my $code    = shift;
    my $amq     = $self->stomp_handle;
    $amq->message_callback($code);
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

