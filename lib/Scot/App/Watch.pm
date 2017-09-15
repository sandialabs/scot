package Scot::App::Watch;

use lib '../../../lib';
use lib '/opt/scot/lib';

=head1 Name

Scot::App::Flair

=head1 Description

watch for things to happen
then do stuff

=cut

use Data::Dumper;
use JSON;
use Try::Tiny;
use Mojo::UserAgent;
use Scot::Env;
use Scot::App;
use Scot::Util::ScotClient;
use Scot::Util::Enrichments;
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

sub _get_img_munger {
    my $self    = shift;
    my $env     = $self->env;
    return $env->img_munger;
};

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

sub run {
    my $self    = shift;
    my $log     = $self->log;
    my $pm      = AnyEvent::ForkManager->new(max_workers => $self->max_workers);
    my $stomp   = AnyEvent::STOMP::Client->new();

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
        $log->debug("STOMP: $action : $type : $id : $who");

        return if ($who eq "scot-flair");

        $pm->start(
            cb      => sub {
                my ($pm, $action, $type, $id) = @_;
                $self->process_message($action, $type, $id);
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

    $id += 0;

    $self->log->debug("Processing Message: $action $type $id");

}


1;
