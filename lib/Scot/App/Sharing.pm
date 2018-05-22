package Scot::App::Sharing;

use lib '../../../lib';

=head1 Name

Scot::App::Sharing

=head1 Description

Application to share data with other SCOT instances via ActiveMQ

=cut

use AnyEvent::STOMP::Client;
use AnyEvent::ForkManager;
use Data::Dumper;
use Try::Tiny;
use JSON;
use Scot::Env;
use Scot::App;
use v5.18;
use strict;
use warnings;

use Moose;
extends 'Scot::App';

=item B<stomp_host>

the hostname of the ActiveMQ broker.  Since Each Scot instance has its
own broker, typically this is localhost.

=cut

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

has stomp_user  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_stomp_user',
);

sub _build_stomp_user {
    my $self    = shift;
    my $attr    = "stomp_user";
    my $default = " ";
    my $envname = "scot_util_stomp_user";
    return $self->get_config_value($attr, $default, $envname);
}

has stomp_pass  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_stomp_pass',
);

sub _build_stomp_pass {
    my $self    = shift;
    my $attr    = "stomp_pass";
    my $default = " ";
    my $envname = "scot_util_stomp_pass";
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
    my $default = 10;
    my $envname = "scot_util_max_workers";
    return $self->get_config_value($attr, $default, $envname);
}

has procmgr => (
    is          => 'rw',
    isa         => 'AnyEvent::ForkManager',
    required    => 1,
    lazy        => 1,
    builder     => '_build_procmgr',
);

sub _build_procmgr {
    my $self    = shift;
    my $workers = $self->max_workers;
    return AnyEvent::ForkManager->new(max_workers => $workers);
}

=item B<send_queue>

This is the queue to put data on for sending out sharable SCOT items.

=cut

has send_queue  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_send_queue',
);

sub _build_send_queue {
    my $self    = shift;
    my $attr    = "send_queue",
    my $default = "share_".$self->env->sitename;
    my $envname = "scot_share_sitename";
    return $self->get_config_value($attr, $default, $envname);
}

=item B<receive_queue>

This is the queue to receive items being shared with us

=cut

has receive_queue => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_receive_queue',
);

sub _build_receive_queue {
    my $self    = shift;
    my $attr    = "receive_queue",
    my $default = "share_".$self->env->remote_sitename;
    my $envname = "scot_share_remote_sitename";
    return $self->get_config_value($attr, $default, $envname);
}

=item B<local_activity_topic>

This topic is SCOT's notification to local site of CRUD activity

=cut

has local_activity_topic => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_activity_topic',
);

sub _build_activity_topic {
    my $self    = shift;
    my $attr    = "activity_topic",
    my $default = "/topic/scot";
    my $envname = "scot_activity_topic";
    return $self->get_config_value($attr, $default, $envname);
}

has stomp   => (
    is          => 'rw',
    isa         => 'AnyEvent::STOMP::Client',
    required    => 1,
    builder     => '_build_stomp',
);

sub _build_stomp {
    my $self    = shift;
    my $host    = $self->stomp_host;
    my $port    = $self->stomp_port;
    my $user    = $self->stomp_user;
    my $pass    = $self->stomp_pass;
    if ( $user ne ' ' and $pass ne ' ' ) {
        return AnyEvent::STOMP::Client->new(
            $host,$port,{ login => $user, passcode => $pass}
        );
    }
    return AnyEvent::STOMP::Client->new(
        $host, $port
    );
}

sub run {
    my $self    = shift;
    my $log     = $self->log;
    my $stomp   = $self->stomp;
    my $pm      = $self->procmgr;

    $stomp->on_connected(sub {
        my $stomp   = shift;
        $log->debug("Subscribing to ".$self->local_activity_topic);
        $stomp->subscribe($self->local_activity_topic);
        $log->debug("Subscribing to ".$self->receive_queue);
        $stomp->subscribe($self->receive_queue);
        $log->debug("Subscribing to ".$self->send_queue);
        $stomp->subscribe($self->send_queue);
    });

    $stomp->on_connect_error( sub {
        my $stomp   = shift;
        $log->error("ERROR connecting to STOMP server.  Retrying in 5 secs");
        sleep 5;
        $stomp->connect();
    });
    
    $stomp->connect();

    $pm->on_start(sub {
        my $pm      = shift;
        my $pid     = shift;
        my $href    = shift;
        my $action  = $href->{action};
        my $type    = $href->{data}->{type};
        my $id      = $href->{data}->{id};

        $log->debug(" +++ worker $pid started to handle $action on $type $id");
    });

    $pm->on_finish(sub {
        my $pm      = shift;
        my $pid     = shift;
        my $status  = shift;
        my $href    = shift;
        my $action  = $href->{action};
        my $type    = $href->{data}->{type};
        my $id      = $href->{data}->{id};

        $log->debug(" +++ worker $pid finished handling $action on $type $id. STATUS = $status");
    });

    $pm->on_error(sub {
        my $pm = shift;
        my $pid     = shift;
        my $href    = shift;
        my $action  = $href->{action};
        my $type    = $href->{data}->{type};
        my $id      = $href->{data}->{id};

        $log->debug(" !!! worker $pid handling $action on $type $id (ERROR)");
    });

    $pm->on_working_max(sub {
        my $pm = shift;
        my $href    = shift;
        my $action  = $href->{action};
        my $type    = $href->{data}->{type};
        my $id      = $href->{data}->{id};

        $log->debug(" MAX worker $$ handling $action on $type $id (ON MAX)");
    });

    $pm->on_enqueue(sub {
        my $pm = shift;
        my $href    = shift;
        my $action  = $href->{action};
        my $type    = $href->{data}->{type};
        my $id      = $href->{data}->{id};

        $log->debug(" ~~~ manager $$ handling $action on $type $id (QUEUED)");
    });

    $pm->on_dequeue(sub {
        my $pm = shift;
        my $href    = shift;
        my $action  = $href->{action};
        my $type    = $href->{data}->{type};
        my $id      = $href->{data}->{id};

        $log->debug(" ### manager $$ handling $action on $type $id (DEQUEUED)");
    });

    $stomp->on_message(sub {
        my $stomp   = shift;
        my $header  = shift;
        my $body    = shift;
        my $href    = decode_json $body;

        $log->debug("STOMP HEADER: ",{filter=>\&Dumper, value=>$header});
        $log->debug("STOMP BODY  : ",{filter=>\&Dumper, value=>$href});

        $pm->start(
            cb  => sub {
                my $procmgr = shift;
                my $href    = shift;

                try {
                    $log->debug("Received: ",{filter=>\&Dumper, value => $href});
                    my $status = $self->process_message($procmgr, $header, $href);
                    $log->debug("=== worker $$ status is $status");
                }
                catch {
                    $log->error("^^^");
                    $log->error("^^^ ERROR CAUGHT");
                    $log->error("^^^ worker $$");
                    $log->error("^^^ ".$_);
                    $log->error("^^^");
                };
            },
            args    =>  [ $href ],
        );
    });

    $stomp->on_error(sub {
        my $stomp   = shift;
        my $header  = shift;
        my $body    = shift;

        $log->error("STOMP ERROR: ");
        $log->error("    Headers: ",{filter=>\&Dumper, value=>$header});
        $log->error("    Body   : ",{filter=>\&Dumper, value=>$body});
    });

    my $cv  = AnyEvent->condvar;
    $cv->recv;
}

sub process_message {
    my $self    = shift;
    my $pm      = shift;
    my $header  = shift;
    my $data    = shift;
    my $log     = $self->env->log;
    my $stomp   = $self->stomp;

    $log->trace("Process Message Begins");

    my $destination = $header->{destination};

    if ( $destination eq "/topic/scot" ) {
        
        $log->debug("Processing a Topic Broadcast");

        my $hostname = $data->{hostname};

        if ( $hostname eq $self->env->sitename ) {

            $log->debug("This topic broadcast was on my scot instance");

            my $send_hdr = {
                'content-type'    => 'text/json'
            };

            $stomp->send($self->env->send_queue, $send_hdr, encode_json($data) );

        }
        else {
            
            $log->debug("This topic was broadcast from elsewhere");

        }
    }
    elsif ( $destination eq $self->env->receive_queue ) {

        $log->debug("Queue message received from other SCOT");
    }
    else {
        $log->error("ERROR: got a message I should not have");
    }

    return 1;

}

1;
