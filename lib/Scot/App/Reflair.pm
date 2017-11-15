package Scot::App::Reflair;

use lib '../../../lib';
use lib '/opt/scot/lib';

=head1 Name

Scot::App::Flair

=head1 Description

listen for newly created user defined flair
ask elastic for all instances
reflair those entries/alerts
profit

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

    $log->debug("Starting REFLAIR daemon");

    $stomp->connect();
    $stomp->on_connected(sub {
        my $stomp    = shift;
        $stomp->subscribe($topic);
        $log->debug("subscribed to $topic");
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
                    my $stat = $self->process_message($procmgr, $action, $type, $id);
                    $log->debug("=== worker $$ status is $stat");
                }
                catch {
                    $log->error("^^^");
                    $log->error("^^^ ERROR CAUGHT");
                    $log->error("^^^ worker $$");
                    $log->error("^^^ $action $type $id:");
                    $log->error("^^^ ".chomp($_));
                    $log->error("^^^");
                };

            },
            args    =>  [ $href ],
        );
    });

    my $cv  = AnyEvent->condvar;
    $cv->recv;
}

sub process_message {
    my $self        = shift;
    my $pm          = shift;
    my $action      = shift;
    my $type        = shift;
    my $id          = shift;
    my $log         = $self->log;

    $log->debug("[Wkr $$] Processing Message $action $type $id");

    if ( $action eq "created" ) {
        $log->debug("--- created message ---");
        if ( $type eq "entitytype" ) {
            $log->debug("--- entitytype ---");
            return $self->process_new_entitytype($id);
        }
    }
    $log->debug("That Message was not for me :-(");
}

sub process_new_entitytype {
    my $self    = shift;
    my $id      = shift;
    my $log     = $self->log;
    my $es      = $self->env->es;

    my $entitytype  = $self->get_entitytype($id);
    unless (defined $entitytype) {
        $log->error("Entitytype id was not found!");
        return "unknown entitytype";
    }
    my $query       = $self->build_es_query($entitytype);
    unless (defined $query) {
        $log->error("Query was not defined!");
        return "failed to build query";
    }
    my $json        = $es->search("scot", ['entry','alert'], $query);
    unless (defined $json) {
        $log->error("elasticsearch search failed");
        return "elasticsearch failed";
    }
    my @results     = $self->parse_results($json);

    foreach my $appearance (@results) {
        $log->debug("Sending message for ",{filter=>\&Dumper, value=>$appearance});
        $self->send_message($appearance);
    }
    return $id;
}

sub get_entitytype {
    my $self    = shift;
    my $id      = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $col     = $mongo->collection('Entitytype');

    $log->debug("looking for entiry id $id");

    my $obj     = $col->find_iid($id);
    return $obj;
}

sub build_es_query {
    my $self        = shift;
    my $entitytype  = shift;

    my $log     = $self->env->log;
    my $value   = $entitytype->value;
    my $match   = $entitytype->match;
    my $id      = $entitytype->id;
    my $json    = {
        query   => {
            match   => {
                _all    => $match
            }
        }
    };
    $log->debug("build es query ",{filter=>\&Dumper,value=>$json});
    return $json;
}

sub send_message {
    my $self    = shift;
    my $href    = shift;
    my $type    = $href->{type};
    my $id      = $href->{id};
    my $mq      = $self->env->mq;
    my $log     = $self->env->log;
    my $msg     = {
        action  => "updated",
        data    => {
            who     => "reflairer",
            type    => $type,
            id      => $id,
        }
    };

    $log->debug("Sending Notification: ", {filter=>\&Dumper, value=>$msg});
    $mq->send("scot", $msg);
}

sub parse_results {
    my $self    = shift;
    my $json    = shift;
    my $log     = $self->env->log;
    my @hits    = @{$json->{hits}->{hits}};
    my @results = ();
    my %seen    = ();

    $log->debug("parsing results");

    foreach my $hit (@hits) {
        my $type    = $hit->{_type};
        $log->debug("found hit type $type");

        if ( defined $type ) {
            if ( $type eq "alert" or $type eq "entry" ) {
                my $id = $hit->{_source}->{id};
                $log->debug("$type id is $id");
                if ( defined $seen{$type}{$id} ) {
                    $log->debug("$type $id already seend");
                    next;
                }
                $seen{$type}{$id}++;
                $log->debug("$type $id being added to results");
                push @results, {
                    id      => $id,
                    type    => $type,
                };
            }
        }
    }
    return wantarray ? @results : \@results;
}



1;
