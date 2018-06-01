package Scot::App::Responder;

use lib '../../../lib';
use lib '/opt/scot/lib';

=head1 Name

Scot::App::Responder

=head1 Description

Apps that listen for AMQ messages can use this as superclass
Classes that subclass this will need to implement process_message();

=cut

use AnyEvent::STOMP::Client;
use AnyEvent::ForkManager;
use Data::Dumper;
use Try::Tiny;
use JSON;
use Scot::Env;
use Scot::App;
use strict;
use warnings;
use v5.18;

use Moose;
extends 'Scot::App';

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
    my $default = 5;
    my $envname = "scot_util_max_workers";
    return $self->get_config_value($attr, $default, $envname);
}

has mode    => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'message', # other supported mode is "test"
);

has procmgr => (
    is          => 'rw',
    isa         => 'AnyEvent::ForkManager',
    required    => 1,
    builder     => '_build_procmgr',
);

sub _build_procmgr {
    my $self    = shift;
    my $workers = $self->max_workers;
    return AnyEvent::ForkManager->new(max_workers => 3);
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
    return AnyEvent::STOMP::Client->new($host,$port);
}

has topic   => (
    is      => 'rw',
    isa     => 'Str',
    required    => 1,
    builder     => '_build_topic',
);

sub _build_topic {
    my $self    = shift;
    my $attr    = "topic";
    my $default = "/topic/scot";
    my $envname = "scot_reflair_topic";
    return $self->get_config_value($attr, $default, $envname);
}

sub run {
    my $self    = shift;
    my $log     = $self->log;
    my $stomp   = $self->stomp;
    my $pm      = $self->procmgr;
    my $topic   = $self->topic;

    my $name    = $self->name;

    $log->debug("Starting Responder $name daemon");

    $stomp->connect();
    $stomp->on_connected(sub {
        my $stomp    = shift;
        $stomp->subscribe($topic);
        $log->debug("subscribed to $topic");
    });

    $stomp->on_connect_error(sub {
        my $stomp   = shift;
        $log->error("ERROR connecting to STOMP server.  Will retry in 10 secs");
        sleep 10;
        $stomp->connect();
    });

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
                my $action  = $href->{action};
                my $type    = $href->{data}->{type};
                my $id      = $href->{data}->{id};

                try { 
                    $log->debug("MSG HREF: ",{filter=>\&Dumper, value => $href});
                    my $stat = $self->process_message($procmgr, $href);
                    $log->debug("=== worker $$ status is $stat");
                }
                catch {
                    $log->error("^^^");
                    $log->error("^^^ ERROR CAUGHT");
                    $log->error("^^^ worker $$");
                    $log->error("^^^ $action $type $id:");
                    # $log->error("^^^ ".chomp($_));
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

1;
