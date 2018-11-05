package Scot::App::Similar;

use lib '../../../lib';
use lib '/opt/scot/lib';

=head1 Name

Scot::App::Similiar

=head1 Description

When new data comes into an event
start looking for other similar events
score them and store results in event record

=cut

use Data::Dumper;
use JSON;
use Try::Tiny;
use Mojo::UserAgent;
use Scot::Env;
use Scot::App;
use Scot::Util::ScotClient;
use AnyEvent::STOMP::Client;
use AnyEvent::ForkManager;
use Module::Runtime qw(require_module);
use Sys::Hostname;
use strict;
use warnings;
# use v5.18;

use Moose;
extends 'Scot::App';

sub process_message {
    my $self    = shift;
    my $action  = lc(shift);
    my $type    = lc(shift);
    my $id      = shift;

    $id += 0;

    $self->log->debug("Processing Message: $action $type $id");

    if ( $action eq "created" or $action eq "updated" ) {
        if ( $type eq "entry" ) {
            $self->process_entry($id);
            $self->put_stat("entry flaired", 1);
        }
        else {
            $self->out("Non-processed type: $type");
        }
    } else {
        $self->out("action $action not processed");
    }
}

sub get_alertgroup {
    my $self    = shift;
    my $id      = shift;
    my $href;
    
    if ( $self->get_method eq "scot_api" ) {
#        my $scot    = $self->scot;
#        $href       = $scot->get({ type => "alertgroup/$id/alert" } );
    }
    else {
        my $mongo       = $self->env->mongo;
        my $collection  = $mongo->collection("Alertgroup");
        $href           = $collection->get_bundled_alertgroup($id);
    }
    return $href;
}


sub get_entry {
    my $self    = shift;
    my $id      = shift;
    my $href;
    $id  += 0;

    $self->log->debug("Getting entry $id");

    if ( $self->get_method eq "scot_api" ) {
#        my $scot    = $self->scot;
#        $href       = $scot->get({ id => $id, type => "entry" } );
    }
    else {
        my $mongo       = $self->env->mongo;
        my $collection  = $mongo->collection("Entry");
        my $entryobj    = $collection->find_iid($id);
        $href           = $entryobj->as_hash;
        $self->log->debug("Entry OBJ = ", {filter=>\&Dumper, value=>$href});
    }
    return $href;
}

sub process_entry {
    my $self    = shift;
    my $id      = shift;
#    my $scot    = $self->scot;
    my $update;
    my $log     = $self->log;

    $log->debug("initial grab of entry $id");
    my $entry   = $self->get_entry($id);

    # start similarity processing
}



1;
