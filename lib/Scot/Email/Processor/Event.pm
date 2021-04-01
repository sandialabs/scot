package Scot::Email::Processor::Event;

use strict;
use warnings;

use Data::Dumper;
use Module::Runtime qw(require_module);
use Moose;
extends 'Scot::Email::Processor';

# $msg will be: 
# {
#   imap_uid => ,
#   subject => ,
#   from => ,
#   to  => ,
#   when    => ,
#   message_id => ,
#   message_str => ,
# }

sub process_message {
    my $self    = shift;
    my $msg     = shift;
    my $log     = $self->env->log;
    my $mbox    = $self->mbox;

    $log->debug("[$mbox->{name}] Processing ".$msg->{subject}.
                " from ".$msg->{from});

    if ( $self->is_health_check($msg) ) {
        $log->warn("[$mbox->{name}] Healthcheck received");
        # TODO: write to db or file so watchdog process sees it
        return; # nothing more necessary
    }

    if ( $self->already_processed($msg) ) {
        $log->warn("[$mbox->{name}] $msg->{message_id} already processed");
        return;
    }

    my $parser  = $self->select_parser($msg);
    my $json    = $parser->parse($msg);

    # $log->debug("Parser returns: ",{filter=>\&Dumper, value=>$json});

    my $event  = $self->create_event($json);

    if ( defined $event and ref($event) eq "Scot::Model::Event" ) {
        $log->debug("Sucess creating Event: ".$event->id);
        return;
    }

    $log->error("Failed to create Event!");
    $log->trace({filter=>\&Dumper, value=>$msg});

}

sub is_health_check {
    my $self    = shift;
    my $msg     = shift;
    my $subject = $msg->{subject};
    return undef;
}

sub select_parser {
    my $self    = shift;
    my $msg     = shift;
    my $env     = $self->env;

    my $class  = "Scot::Email::Parser::Event";

    require_module($class);
    my $instance = $class->new({env => $env});
    return $instance;
}

sub already_processed {
    my $self    = shift;
    my $msg     = shift;
    my $mid     = $msg->{message_id};

    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Event');
    my $event   = $col->find_one({"data.message_id" => $mid});
    return defined $event;
}

sub create_event {
    my $self    = shift;
    my $data    = shift;

    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Event');

    $log->debug("creating event");

    if ( $self->dry_run ) {
        $log->debug("Would have created Event(s) from: ",
                    {filter => \&Dumper, value => $data});
        return;
    }

    my $event = $self->create_event_obj($data->{event});
    my $entry = $self->create_entry_obj($event, $data->{entry});

    $self->scot_housekeeping($event, $entry);
    return $event;
}

sub create_event_obj {
    my $self    = shift;
    my $data    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $col     = $mongo->collection('Event');

    $log->debug("creating event obj");

    my $event = $col->create($data);

    if (defined $event and ref($event) eq "Scot::Model::Event") {
        return $event;
    }
    $log->error("Failed to create Event with ",
                { filter=>\&Dumper, value => $data});
    return undef;
}

sub create_entry_obj {
    my $self    = shift;
    my $event   = shift;
    my $data    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $col     = $mongo->collection('Entry');

    $log->debug("creating entry obj");

    $data->{target} = { type => "event", id => $event->id };
    $data->{groups} = $event->groups;
    $data->{summary} = 0;
    $data->{tlp}    = $event->tlp;

    my $entry = $col->create($data);

    if ( defined $entry and ref($entry) eq "Scot::Model::Entry") {
        return $entry;
    }
    $log->error("Failed to create Entry with: ",
                { filter=>\&Dumper, value => $data});
    return undef;

}

sub scot_housekeeping {
    my $self    = shift;
    my $event   = shift;
    my $entry   = shift;
    my $env     = $self->env;
    my $mq      = $env->mq;
    
    $self->notify_flair_engine($event, $entry);
    $self->begin_history($event, $entry);
    $self->update_stats($event, $entry);
}

sub notify_flair_engine {
    my $self        = shift;
    my $event       = shift;
    my $entry       = shift;
    my $mq          = $self->env->mq;
    $mq->send("/topic/scot", {
        action  => "created",
        data    => {
            type    => "event",
            id      => $event->id,
            who     => "scot-events",
        }
    });
    $mq->send("/topic/scot", {
        action  => "created",
        data    => {
            type    => "entry",
            id      => $entry->id,
            who     => "scot-events",
        }
    });
}

sub begin_history {
    my $self        = shift;
    my $event       = shift;
    my $entry       = shift;
    my $mongo       = $self->env->mongo;

    $mongo->collection('History')->add_history_entry({
        who     => 'scot-events',
        what    => 'created event',
        when    => time(),
        target  => { id => $event->id, type => "event" },
    });
    $mongo->collection('History')->add_history_entry({
        who     => 'scot-events',
        what    => 'created entry',
        when    => time(),
        target  => { id => $entry->id, type => "entry" },
    });
}

sub update_stats {
    my $self        = shift;
    my $event       = shift;
    my $entry       = shift;
    my $mongo       = $self->env->mongo;
    my $now         = DateTime->now;
    my $col         = $mongo->collection('Stat');

    $col->increment($now, "entry created", 1);
    $col->increment($now, "event created", 1);
}


1;


