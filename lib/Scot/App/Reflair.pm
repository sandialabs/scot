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

use Data::Dumper;
use JSON;
use Try::Tiny;
use Mojo::UserAgent;
use Scot::Env;
use Scot::App;
use AnyEvent::STOMP::Client;
use AnyEvent::ForkManager;
use HTML::Entities;
use Module::Runtime qw(require_module);
use Sys::Hostname;
use strict;
use warnings;
use v5.18;

use Moose;
extends 'Scot::App';

has get_method  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'mongo',
);

has thishostname    =>  (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => sub { hostname; },
);

has extractor   => (
    is          => 'ro',
    isa         => 'Scot::Extractor::Processor',
    required    => 1,
    lazy        => 1,
    builder     => '_get_entity_extractor',
);

sub _get_entity_extractor {
    my $self    = shift;
    my $env     = $self->env;
    return $env->extractor;
};

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

has interactive => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    default     => 0,
);

sub _build_interactive {
    my $self    = shift;
    my $attr    = "interactive";
    my $default = 0;
    my $envname = "scot_util_entityextractor_interactive";
    return $self->get_config_value($attr, $default, $envname);
}

has enrichers   => (
    is              => 'ro',
    isa             => 'Scot::Util::Enrichments',
    required        => 1,
    lazy            => 1,
    builder         => '_get_enrichers',
);

sub _get_enrichers {
    my $self    = shift;
    my $env     = $self->env;
    return $env->enrichments;
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
    my $default = 20;
    my $envname = "scot_util_max_workers";
    return $self->get_config_value($attr, $default, $envname);
}

sub out {
    my $self    = shift;
    my $msg     = shift;

    if ( $self->interactive ) {
        say $msg;
    }
}

has mode    => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'message', # other supported mode is "test"
);

sub run {
    my $self    = shift;
    my $log     = $self->log;
    my $pm      = AnyEvent::ForkManager->new(max_workers => $self->max_workers);
    my $stomp;

    if ( $self->stomp_host ne "localhost" ) {
        $stomp   = 
            AnyEvent::STOMP::Client->new($self->stomp_host, $self->stomp_port);
    }
    else {
        $stomp = AnyEvent::STOMP::Client->new;
    }

    $stomp->connect();
    $stomp->on_connected(sub {
        my $s   = shift;
        $s->subscribe('/topic/scot');
        $self->out("---- subcribed to /topic/scot via STOMP ---");
        $log->debug("Subcribed to /topic/scot");
    });

    $pm->on_start(sub {
        my ($pm, $pid, $action, $type, $id) = @_;
        $self->out("------ Worker $pid handling $action on $type $id");
        $log->debug("Worker $pid handling $action on $type $id started");
    });

    $pm->on_finish(sub {
        my ($pm, $pid, $status, $action, $type, $id) = @_;
        $self->out("------ Worker $pid finished $action on $type $id: $status");
        $log->debug("Worker $pid handling $action on $type $id finished");
    });

    $pm->on_error(sub {
        $self->out("FORKMGR ERROR: ".Dumper(\@_));
    });


    $stomp->on_message(sub {
        my ($stomp, $header, $body) = @_;

        $log->debug("Header: ",{filter=>\&Dumper, value => $header});

        my $href = decode_json $body;
        $log->debug("Body: ",{filter=>\&Dumper, value => $href});

        my $action  = $href->{action};
        my $type    = $href->{data}->{type};
        my $id      = $href->{data}->{id};
        my $who     = $href->{data}->{who};
        my $opts    = $href->{data}->{opts};
        $log->debug("STOMP: $action : $type : $id : $who : $opts");

        # return if ($who eq "scot-flair");

        $pm->start(
            cb      => sub {
                my ($pm, $action, $type, $id) = @_;
                $self->process_message($action, $type, $id, $opts);
            },
            args    => [ $action, $type, $id ],
        );
        
    });

    my $cv  = AnyEvent->condvar;
    $cv->recv;

}

sub process_message {
    my $self    = shift;
    my $action  = lc(shift);
    my $type    = lc(shift);
    my $id      = shift;
    my $opts    = shift;

    $id += 0;

    $self->log->debug("Processing Message: $action $type $id");

    if ( $action eq "created user defined entity" ) {
        # get instances from elastic search
        my @appearances = $self->find_appearances($id);        
        # iterate and reflair
        $self->cause_reflair(@appearances);
    } 
    else {
        $self->out("action $action not processed");
    }
}

sub find_appearances {
    my $self    = shift;
    my $id      = shift;                # id of the entity we are looking for
    my $index   = shift;
    my $es      = $self->env->es;
    my $entity  = $self->get_entity($id);
    my $query   = $self->build_es_query($entity);
    my $json    = $es->search($index, undef, $query);

    # parse out the returned objects of form [ {type,id}, ... ]
    my @results = $self->parse_results($json);
    return wantarray ? @results : \@results;
}

sub cause_reflair {
    my $self        = shift;
    my @appearances  = @_;

    foreach my $appearance (@appearances) {
        if ( $self->mode eq "message" ) {
            $self->send_notification($appearance);
        }
        else {
            say "Appearance: ".Dumper($appearance);
        }
    }
}

sub get_entity {
    my $self    = shift;
    my $id      = shift;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Entity');
    my $obj     = $col->find_iid($id);
    return $obj;
}

sub build_es_query {
    my $self    = shift;
    my $entity  = shift;
    my $value   = $entity->value;
    my $id      = $entity->id;
    my $json    = {
        query   => {
            match   => {
                _all    => $value
            }
        }
    };
    return $json;
}

sub send_notification {
    my $self    = shift;
    my $href    = shift;
    my $type    = $href->{type};
    my $id      = $href->{id};
    my $mq      = $self->env->mq;

    $mq->send("scot", {
        action  => "updated",
        data    => {
            who     => "reflairer",
            type    => $type,
            id      => $id,
        }
    });
}

sub parse_results {
    my $self    = shift;
    my $json    = shift;
    my @hits    = @{$json->{hits}->{hits}};
    my @results = ();
    my %seen    = ();

    foreach my $hit (@hits) {
        my $type    = $hit->{_type};

        if ( defined $type ) {
            if ( $type eq "alert" or $type eq "entry" ) {
                my $id = $hit->{_source}->{id};
                if ( defined $seen{$type}{$id} ) {
                    next;
                }
                $seen{$type}{$id}++;
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
