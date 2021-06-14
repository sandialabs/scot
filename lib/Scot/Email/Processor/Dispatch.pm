package Scot::Email::Processor::Dispatch;

use strict;
use warnings;

use Data::Dumper;
use Module::Runtime qw(require_module);
use Moose;
extends 'Scot::Email::Processor';

sub process_message {
    my $self    = shift;
    my $msg     = shift;
    my $mbox    = $self->mbox;
    my $log     = $self->env->log;

    $log->debug("[$mbox->{name}] Processing ".$msg->{subject}.
                " from ".$msg->{from});

    if ( $self->already_processed($msg) ) {
        $log->warn("[$mbox->{name}] $msg->{message_id} already in SCOT");
        return 1;
    }

    my $parser  = $self->select_parser($msg);
    my $data    = $parser->parse($msg);

    if ( defined $data ) {

        my $dispatch = $self->create_dispatch($data);
        if ( defined $dispatch and ref($dispatch) eq "Scot::Model::Dispatch") {
            $log->debug("Success creaing dispatch: ".$dispatch->id);
            return 1;
        }
    }

    $log->error("Failed to create dispatch!");
    $log->debug({filter => \&Dumper, value => $msg});
    return undef;
}

sub select_parser {
    my $self    = shift;
    my $msg     = shift;
    my $class = "Scot::Email::Parser::Dispatch";
    require_module($class);
    my $instance = $class->new({env => $self->env});
    return $instance;
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

    my $dispatch = $self->create_dispatch_obj($dispatch_data);
    my $entry    = $self->create_entry($dispatch, $entry_data);

    my @files    = $self->process_attachments($dispatch, $attachment_data);

    if (defined $dispatch) {
        $self->scot_housekeeping($dispatch, $entry, \@files);
    }

}

sub scot_housekeeping {
    my $self    = shift;
    my $dispatch = shift;
    my $entry   = shift;
    my $files   = shift;

    $self->notify_flair_engine($dispatch, $entry);
    $self->begin_history($dispatch, $entry);
    $self->update_stats($dispatch, $entry);
}

sub notify_flair_engine {
    my $self    = shift;
    my $dispatch = shift;
    my $entry   = shift;
    my $mq      = $self->env->mq;

    $mq->send("/topic/scot", {
        action  => "created",
        data    => { 
            type    => 'dispatch',
            id      => $dispatch->id,
            who     => 'scot-feeds',
        }
    });
    $mq->send("/topic/scot", {
        action  => "created",
        data    => { 
            type    => 'entry',
            id      => $entry->id,
            who     => 'scot-feeds',
        }
    });

}

sub begin_history {
    my $self        = shift;
    my $dispatch    = shift;
    my $entry       = shift;
    my $mongo       = $self->env->mongo;

    $mongo->collection('History')->add_history_entry({
        who     => 'scot-feeds',
        what    => 'created dispatch',
        when    => time(),
        target  => { id => $dispatch->id, type => "dispatch" },
    });

    $mongo->collection('History')->add_history_entry({
        who     => 'scot-feeds',
        what    => 'created entry',
        when    => time(),
        target  => { id => $entry->id, type => "entry" },
    });
}

sub update_stats {
    my $self        = shift;
    my $dispatch    = shift;
    my $entry       = shift;
    my $mongo       = $self->env->mongo;
    my $now         = DateTime->now;
    my $col         = $mongo->collection('Stat');

    $col->increment($now, "dispatch created", 1);
    $col->increment($now, "entry created", 1);
}

sub create_dispatch_obj {
    my $self    = shift;
    my $data    = shift;
    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Dispatch');

    $log->debug("Creating Dispatch Object");
    $log->debug("Dispatch Data is ",{filter=>\&Dumper, value=>$data});

    my $dispatch = $col->create($data);

    if ( defined $dispatch and ref($dispatch) eq "Scot::Model::Dispatch" ){
        return $dispatch;
    }
    $log->error("Failed to create Dispatch with ",
                { filter => \&Dumper, value => $data});
    return undef;
}

sub create_entry {
    my $self    = shift;
    my $dispatch = shift;
    my $data    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $col     = $mongo->collection('Entry');

    # { target, groups, summary, body, owner }

    $data->{target} = {
        type    => 'dispatch',
        id      => $dispatch->id,
    };
    $data->{groups} = $dispatch->groups;
    $data->{owner} = $dispatch->owner;
    $data->{summary} = 0;
    $data->{tlp} = $self->get_tlp($data, $dispatch);
    $data->{tlp} = $data->{tlp} // $dispatch->tlp;

    my $entry = $col->create($data);

    if ( defined $entry and ref($entry) eq "Scot::Model::Entry" ) {
        return $entry;
    }
    $log->error("Failed to create Entry with: ",
                { filter => \&Dumper, value => $data });
    return undef;
}

sub get_tlp {
    my $self    = shift;
    my $data    = shift;
    my $dispatch = shift;

    return $data->{tlp} if defined $data->{tlp};
    return $dispatch->tlp if defined $dispatch->tlp;
    return 'unset';
}

sub process_attachments {
    my $self    = shift;
    my $dispatch = shift;
    my $data    = shift;
    my $log     = $self->env->log;

    $log->debug("Attachment handling not implemented, yet.");

}

1;
