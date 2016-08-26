package Scot::App::Replicate;

use lib '../../../lib';

=head1 Name

Scot::App::Replicate

=head1 Description

Watch for amq events
copy data to another SCOT

=cut

use Data::Dumper;
use JSON;
use Try::Tiny;
use Mojo::UserAgent;
use Scot::Env;
use Scot::App;
use Scot::Util::Scot;
use Scot::Util::EntityExtractor;
use Scot::Util::ImgMunger;
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

has thishostname    =>  (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => sub { hostname; },
);


has thisscot    => (
    is          => 'ro',
    isa         => 'Scot::Util::Scot',
    required    => 1,
    lazy        => 1,
    builder     => '_build_this_scot',
);

sub _build_this_scot {
    my $self    = shift;
    # say Dumper($self->config);
    return Scot::Util::Scot->new({
        log         => $self->log,
        servername  => $self->config->{source}->{scot}->{servername},
        username    => $self->config->{source}->{scot}->{username},
        password    => $self->config->{source}->{scot}->{password},
        authtype    => $self->config->{source}->{scot}->{authtype},
    });
}

has thatscot    => (
    is          => 'ro',
    isa         => 'Scot::Util::Scot',
    required    => 1,
    lazy        => 1,
    builder     => '_build_that_scot',
);

sub _build_that_scot {
    my $self    = shift;
    # say Dumper($self->config);
    return Scot::Util::Scot->new({
        log         => $self->log,
        servername  => $self->config->{dest}->{scot}->{servername},
        username    => $self->config->{dest}->{scot}->{username},
        password    => $self->config->{dest}->{scot}->{password},
        authtype    => $self->config->{dest}->{scot}->{authtype},
    });
}

has interactive => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    default     => 0,
);


sub run {
    my $self    = shift;
    my $log     = $self->log;

    $log->debug("Starting STOMP watcher");
    # $log->debug("Config is ",{filter=>\&Dumper,value=>$self->config});

    my $pm  = AnyEvent::ForkManager->new(max_workers => 10);

    $pm->on_start( sub {
        my ($pm, $pid, $action, $type, $id) = @_;
        $log->debug("Starting worker $pid to handle $action on $type $id");
    });

    $pm->on_finish( sub {
        my ($pm, $pid, $status, $action, $type, $id) = @_;
        $log->debug("Ending worker $pid to handle $action on $type $id");
    });

    $pm->on_error( sub {
        $log->error("Error encountered", {filter=>\&Dumper, value=>\@_});
    });

    my $stomp   = new AnyEvent::STOMP::Client();

    my $subscribe_headers   = {
        id                          => $self->thishostname,
        'activemq.subscriptionName' => 'scot-queue',
    };

    my $connect_headers = {
        'client-id' => 'scot-queue',
    };

    $stomp->connect();

    $stomp->on_connected(
        sub {
            my $stomp    = shift;
            $stomp->subscribe('/topic/scot');
            if ( $self->interactive ) {
                say "==== Listening via STOMP to /topic/scot =====";
            }
        }
    );

    my $scot        = $self->thisscot;

    $stomp->on_message(
        sub {
            my ($stomp, $header, $body) = @_;
            $log->debug("-"x50);
            $log->debug("Received STOMP Message");
            $log->debug("header : ", { filter => \&Dumper, value => $header});
            $log->debug("body   : ", { filter => \&Dumper, value => $body});

            # read $body to determine alert or entry number
            my $json    = decode_json $body;
            # $log->debug("body   : ", { filter => \&Dumper, value => $json});
            say "----------------- JSON Message -------------";
            say Dumper($json);
            say "----------------- ------------ -------------";
            
            my $type    = $json->{data}->{type};
            my $id      = $json->{data}->{id};
            my $who     = $json->{data}->{who};
            my $action  = $json->{action};

            if ( $self->interactive ) {
                say "---";
                say "--- $action message received";
                say "--- $type $id ($who)";
                say "---";
            }

            $pm->start(
                cb  => sub {
                    my ($pm, $action, $type, $id) = @_;

                    $log->debug("Getting $type $id from SCOT");

                    my $record = $scot->get($type,$id);

                    if ( $self->interactive ) {
                        say "+ got $type $id from scot: "; # .
                            # Dumper($record);
                    }

                    $log->debug("GET Response: ", 
                                { filter => \&Dumper, value => $record });

                    $self->process_record($action, $type, $id, $record);

                    if ( $self->interactive ) {
                        say "   --- processed $type $id";
                    }
                },
                args    => [ $action, $type, $id ],
            );
            $log->debug("-"x50);
        }
    );

    my $cv  = AnyEvent->condvar;

    $cv->recv;
}

sub process_record {
    my $self    = shift;
    my $action  = shift;
    my $type    = shift;
    my $id      = shift;
    my $href    = shift; #... the record as a hash ref
    my $log     = $self->log;
    my $scot    = $self->thatscot;

    delete $href->{_id};
    
    if ( $action eq "created" ) {
        delete $href->{id};
        $log->debug("Creating $type");
        $scot->post($type, $href);
    }
    elsif ( $action eq "updated" ) {
        $log->debug("Updating $type $id");
        $scot->put($type, $href->{id}, $href);
    }
    elsif ( $action eq "deleted" ) {
        $log->debug("Deleting $type $id");
        $scot->delete($type, $id);
    }
    else {
        if ( $self->interactive ) {
            say " !!! unsupported action $action !!!";
        }
        $log->error("Unspported Action $action");
    }
}


1;
