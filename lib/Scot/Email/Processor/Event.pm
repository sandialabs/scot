package Scot::Email::Processor::Event;

use strict;
use warnings;

use Data::Dumper;
use Module::Runtime qw(require_module);
use File::Path qw(make_path);
use File::Slurp;
use Try::Tiny;
use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(sha1_hex sha256_hex);
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
        return 1; # nothing more necessary
    }

    if ( $self->already_processed($msg) ) {
        $log->warn("[$mbox->{name}] $msg->{message_id} already processed");
        return 1;
    }

    my $parser  = $self->select_parser($msg);
    my $json    = $parser->parse($msg);

    # $log->debug("Parser returns: ",{filter=>\&Dumper, value=>$json});

    my $event  = $self->create_event($json);

    if ( defined $event and ref($event) eq "Scot::Model::Event" ) {
        $log->debug("Sucess creating Event: ".$event->id);
        return 1;
    }

    $log->error("Failed to create Event!");
    $log->trace({filter=>\&Dumper, value=>$msg});
    return undef;
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
    my $attachments = $self->add_attachments(
        $event, $entry, $data->{attachments}
    );

    $self->scot_housekeeping($event, $entry, $attachments);
    return $event;
}

sub add_attachments {
    my $self    = shift;
    my $event   = shift;
    my $entry   = shift;
    my $data    = shift;
    my $log     = $self->env->log;
    my @entries = ();

    FILE:
    foreach my $href (@$data) {
        my $filename    = $href->{filename};
        my $content     = $href->{content};
        my $mime_type   = $href->{mime_type};
        my $multipart   = $href->{multipart};

        $log->debug("Filename = $filename");
        $log->debug("mime_type= $mime_type");
        $log->debug("multipart= $multipart");
        $log->debug("content is ".length($content)." chars");

        if ( $multipart ) {
            # figure this out later
            $log->warn("Multipart Email Attachment detected. Skipping");
            next FILE;
        }

        if ( $mime_type eq "message/rfc822" ) {
            # figure this out later
            $log->warn("RFC822 Message detected.");

            push @entries, $self->create_822_entry($event, $href);

            next FILE;
        }

        if ( $filename  eq '' ) {
            $log->warn("No Filename!  skipping");
            next FILE;
        }

        if ( my $fqn = $self->save_attachment($event, $href) ) {
            my $file = $self->create_file_obj($event, $href, $fqn);
            push @entries, $self->create_attachment_entry($event, $entry, $href, $file);
        }
        else {
            $log->error("Attechment processing failed.  Skipping...");
        }
    }
    return wantarray ? @entries : \@entries;
}

sub create_822_entry {
    my $self    = shift;
    my $event   = shift;
    my $data    = shift;
    my $body    = $data->{content};
    my $env     = $self->env;
    # finish this later
    return;

    require_modue("Scot::Email::Parser::Email822");
    my $parser  = Scot::Email::Parser::Email822->new({env => $env});
    my $mdata    = $parser->parse({ message_str => $body });


}

sub save_attachment {
    my $self    = shift;
    my $event   = shift;
    my $data    = shift;
    my $log     = $self->env->log;

    my $filename = $data->{filename};
    my $save_dir = $self->get_save_dir($event);
    my $fqn      = join('/',$save_dir,$filename);

    if ( ! $data->{content} ) {
        $log->debug("skipping attachment with empty contents");
        return undef;
    }
    try {
        open(my $fh, ">", $fqn) or die "Failed opening $fqn for writing!";
        print $fh $data->{content};
        close $fh;
    }
    catch {
        $log->error("SAVE Attachment ERROR: $_");
        $fqn = undef;
    };

    return $fqn;
}

sub get_save_dir {
    my $self    = shift;
    my $event   = shift;
    my $id      = $event->id;
    my $dt      = DateTime->now;
    my $year    = $dt->year;
    my $dir     = join('/', $self->env->file_store_root,
                            $year,
                            'event',
                            $id);
    my $err;
    unless ( -d $dir ) {
        make_path($dir, { error => \$err, mode => 0775 });
    }
    if ( defined $err && @$err ) {
        $self->log_mkdir_err($err);
    }
    return $dir;
}

sub log_mkdir_err {
    my $self    = shift;
    my $err     = shift;
    my $log     = $self->env->log;

    for my $diag (@$err) {
        my ($f,$m) = %$diag;
        if ( $f eq '') { 
            $log->error("General MakePath Error: $m"); 
        }
        else {
            $log->error("Problem with make_path($f): $m");
        }
    }
}

sub create_file_obj {
    my $self    = shift;
    my $event   = shift;
    my $data    = shift;
    my $fqn     = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my $filedata    = $self->get_file_basics($data, $fqn);

    $filedata->{filename} = (split('/',$fqn))[-1];
    $filedata->{groups} = $event->groups;
    $filedata->{target} = { type => 'event', id => $event->id };

    $log->debug("creating file obj");
    my $col = $mongo->collection('File');
    my $fileobj = $col->create($filedata);

    if ( ! defined $fileobj or ref($fileobj) ne "Scot::Model::File" ) {
        $log->error("Failed to create file object!");
        return undef;
    }

    return $fileobj;
}

sub get_file_basics {
    my $self    = shift;
    my $data    = shift;
    my $fqn     = shift;

    my $fd      = read_file($fqn);
    my $hashes  = $self->get_hashes($fd);
    my $size    = -s $fqn;
    my $dir     = $self->get_dir_from_fqn($fqn);

    $hashes->{size} = $size;
    $hashes->{directory} = $dir;

    return $hashes;
}

sub get_hashes {
    my $self    = shift;
    my $data    = shift;

    return {
        md5     => md5_hex($data),
        sha1    => sha1_hex($data),
        sha256  => sha256_hex($data),
    };
}

sub get_dir_from_fqn {
    my $self    = shift;
    my $fqn     = shift;
    my @parts   = split('/',$fqn);
    my $filename    = pop @parts;
    my $dir         = join('/', @parts);
    $self->env->log->debug("DIR = $dir");
    return $dir;
}


sub create_attachment_entry {
    my $self    = shift;
    my $event   = shift;
    my $entry   = shift;
    my $data    = shift;
    my $file    = shift;

    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my $col     = $mongo->collection('Entry');
    my $newentry   = $col->create_from_file_upload(
        $file, $entry->id, "event", $event->id
    );

    return $newentry;
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
    $data->{tlp}    = $self->get_tlp($data, $event);

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
    my $attachments = shift;
    my $env     = $self->env;
    my $mq      = $env->mq;
    
    $self->notify_flair_engine($event, $entry,$attachments);
    $self->begin_history($event, $entry,$attachments);
    $self->update_stats($event, $entry,$attachments);
}

sub notify_flair_engine {
    my $self        = shift;
    my $event       = shift;
    my $entry       = shift;
    my $attachments = shift;
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
    foreach my $a (@$attachments) {
        $mq->send("/topic/scot", {
            action  => "created",
            data    => {
                type    => "entry",
                id      => $a->id,
                who     => "scot-events",
            }
        });
    }

}

sub begin_history {
    my $self        = shift;
    my $event       = shift;
    my $entry       = shift;
    my $attachments = shift;
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
    foreach my $a (@$attachments) {
        $mongo->collection('History')->add_history_entry({
            who     => 'scot-events',
            what    => 'created entry',
            when    => time(),
            target  => { id => $a->id, type => "entry" },
        });
    }
}

sub update_stats {
    my $self        = shift;
    my $event       = shift;
    my $entry       = shift;
    my $attachments = shift;
    my $mongo       = $self->env->mongo;
    my $now         = DateTime->now;
    my $col         = $mongo->collection('Stat');

    $col->increment($now, "entry created", 1 + scalar(@$attachments));
    $col->increment($now, "event created", 1);
}


1;


