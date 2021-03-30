package Scot::Email::Processor::Dispatch;

use strict;
use warnings;

use Data::Dumper;
use Moose;
extends 'Scot::Email::Processor';

sub process_message {
    my $self    = shift;
    my $msg     = shift;

    my $log     = $self->env->log;

    if ( $self->already_processed($msg) ) {
        $log->warn("[$mbox->{name}] $msg->{message_id} already in SCOT");
        return;
    }

    my $parser  = $self->select_parser($msg);
    my $data    = $parser->parse($msg);
    my $dispatch = $self->create_dispatch($data);

    if ( defined $dispatch and ref($dispatch) eq "Scot::Model::Dispatch") {
        $log->debug("Success creaing dispatch: ".$dispatch->id);
        return;
    }

    $log->error("Failed to create dispatch!");
    $log->trace({filter => \&Dumper, value => $msg});
}

sub select_parser {
    my $self    = shift;
    my $msg     = shift;

    return "Scot::Email::Parser::Dispatch";
}

sub already_processed {
    my $self    = shift;
    my $msg     = shift;
    my $mid     = $msg->{message_id};
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Dispatch');
    my $dispatch = $col->find_one({"data.message_id" => $mid});
    return defined $dispatch;
}

sub create_dispatch {
    my $self    = shift;
    my $data    = shift;

    my $dispatch_data   = $data->{dispatch};
    my $attachment_data = $data->{attachments};
    my $entry_data      = $data->{entry};

    my $dispatch = $self->create_dispatch($dispatch_data);
    my $entry    = $self->create_entry($dispatch, $entry_data);

    my @files    = $self->process_attachments($dispatch, $attachment_data);

    if (defined $dispatch) {
        $self->scot_housekeeping($dispatch, $entry, \@files);
    }

}

sub create_dispatch {
    my $self    = shift;
    my $data    = shift;
}

sub create_entry {
    my $self    = shift;
    my $dispatch = shift;

}

sub process_attachments {
    my $self    = shift;
    my $dispatch = shift;
    my $data    = shift;

}

1;
