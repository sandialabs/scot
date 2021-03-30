package Scot::Email::Responder::EventPass;

use strict;
use warnings;
use Try::Tiny;
use File::Slurp;
use File::Path qw(make_path);
use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(sha1_hex sha256_hex);
use MIME::Base64;
use File::Path qw(make_path);
use Data::Dumper;
use Module::Runtime qw(require_module compose_module_name);
use Moose;
extends 'Scot::Email::PFResponder';

has name => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
    default => 'EventPass',
);

has parsers => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    builder     => '_build_parsers',
);

sub _build_parsers {
    my $self                = shift;
    my @parser_class_names  = (qw(
        Scot::Email::Parser::PassThrough
    ));    
    my @parsers = ();
    foreach my $cname (@parser_class_names) {
        require_module($cname);
        push  @parsers, $cname->new({ env => $self->env });
    }
    return wantarray ? @parsers : \@parsers;
}

sub _build_max_workers {
    my $self        = shift;
    my $package     = __PACKAGE__;
    my $responder   = $self->get_config_value("responders", undef, undef);
    my $workers     = 1;
    if (defined $responder) {
        if (defined $responder->{workers} ) {
            $workers     = $responder->{workers};
        }
    }
    return $workers;
}

has create_method => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'create_via_mongo',
);

sub process_message {
    my $self    = shift;
    my $pm      = shift;
    my $href    = shift;
    my $data    = $href->{email};
    my $log     = $self->env->log;

    $log->debug("[Wkr $$] Processing Alert");

    if ( $self->is_health_check($data) ) {
        $log->warn("[Wkr $$] Finished: Skipping Health Check Message");
        return 1;
    }

    PARSE:
    foreach my $parser (@{$self->parsers}) {

        if ( ! $parser->will_parse($data) ) {
            $log->warn(ref($parser)." will not parse this data");
            next PARSE;
        }

        if ( $self->create_event($parser, $data) ) {
            $log->debug("Created Event");
            return 1;
        }

        $log->error("Failed to create event from ");
        $log->trace({ filter => \&Dumper, value => $data });
    }
    $log->warn("[Wkr $$] Finished but failed");
    return undef;
}

sub is_health_check {
    my $self    = shift;
    my $data    = shift;
    # no health checks yet

    return undef;
}

sub create_event {
    my $self    = shift;
    my $parser  = shift;
    my $data    = shift;
    my $method  = $self->create_method;

    $self->env->log->debug("create event with ".ref($parser));

    my $evdata  = $parser->parse_message($data);
    my $created = $self->$method($evdata);
    return $created;
}

sub create_via_mongo {
    my $self    = shift;
    my $data    = shift;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Event');
    my $log     = $self->env->log;

    $log->debug("create_via_mongo");
    $log->trace({filter => \&Dumper, value => $data});

    if ( ! $self->already_inserted($data) ) {

        $log->debug("new message");

        my $attachments = delete $data->{attachments};
        my $entry_data  = delete $data->{entry};
        my $event_data  = $data->{event};

        $log->debug("event_data ",{filter=>\&Dumper, value=>$event_data});

        my $event;

        if ( $event = $self->find_subject_match($event_data) ) {
            $log->warn("Message matches existing event ".$event->subject);
        }
        else {
            $log->debug("Creating new event");
            $event = $col->api_create({
                user    => 'scot-admin',
                request => {
                    json => $event_data,
                }
            });
        }

        if ( ! defined $event ) {
            $log->error("Failed to create an event!");
            return undef;
        }

        my $entry = $self->create_entry($event, $entry_data);

        if ( ! defined $entry ) {
            $log->debug("Failed to create first entry");
            return undef;
        }

        my @entries = $self->save_attachments($event, $attachments, $entry);
        unshift @entries, $entry; # put orig entry at first
        $self->scot_housekeeping($event, \@entries);
        return 1;
    }
    $log->debug("already inserted");
    return 1;
}

sub find_subject_match {
    my $self    = shift;
    my $data    = shift;
    my $message_subject   = $data->{subject};
    my $match;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    if ( $message_subject eq "[***OUO***] Pre-Employment Background Review"){
        return undef;
    }

    # strip any "RE: or FW:" from the front of the subject
    ($match = $message_subject) =~ s/^[RE:|FW:]* (.*)$/$1/i;
    $match =~ s/\*/\\*/g;
    $match =~ s/\[/\\[/g;
    $match =~ s/\]/\\]/g;

    $log->debug("subject is $message_subject");
    $log->debug("match   is $match");

    my $regex = qr/$match/i;
    
    my $query   = {
        subject => $regex,
    };

    my $entry = $mongo->collection('Event')->find_one($query);

    if ( $entry ) {
        $log->debug("Found a match: ".$entry->subject);
        return $entry;
    }
    $log->debug("no match");
    return undef;
}

sub create_entry {
    my $self    = shift;
    my $event   = shift;
    my $data    = shift;
    my $mongo   = $self->env->mongo;

    my $col = $mongo->collection("Event");
    my $entry   = $col->create_event_entry($event, $data->{body});
    return $entry;
}

sub already_inserted {
    my $self    = shift;
    my $data    = shift;
    my $msgid   = $data->{event}->{data}->{message_id};

    if ( ! defined $msgid ) {
        $self->env->log->error("NO MESSAGE ID!");
        return undef;
    }

    my $event   = $self->env->mongo->collection('Event')->get_by_msgid($msgid);
    # $self->env->log->debug("Event", {filter=>\&Dumper, value=>$event});

    return defined $event ;
}

sub create_via_api {
    my $self    = shift;
    my $data    = shift;
    # TODO
}

sub scot_housekeeping {
    my $self    = shift;
    my $event   = shift; 
    my $entries = shift;
    my $env     = $self->env;
    my $mq      = $env->mq;
    
    $self->notify_flair_engine($event, $entries);
    $self->begin_history($event);
    $self->update_stats($event);
}

sub notify_flair_engine {
    my $self        = shift;
    my $event       = shift;
    my $entries     = shift;
    my $mq          = $self->env->mq;
    $mq->send("/topic/scot", {
        action  => "created",
        data    => {
            type    => "event",
            id      => $event->id,
            who     => "scot-alerts",
        }
    });
    foreach my $entry (@$entries) {
        $mq->send("/topic/scot", {
            action  => "created",
            data    => {
                type    => "entry",
                id      => $entry->id,
                who     => "scot-alerts",
            },
        });
    }
}

sub begin_history {
    my $self        = shift;
    my $event       = shift;
    my $entries     = shift;
    my $mongo       = $self->env->mongo;

    $mongo->collection('History')->add_history_entry({
        who     => 'scot-alerts',
        what    => 'created event',
        when    => time(),
        target  => { id => $event->id, type => "event" },
    });
    foreach my $entry (@$entries) {
        $mongo->collection('History')->add_history_entry({
            who     => 'scot-alerts',
            what    => 'created entry',
            when    => time(),
            target  => { id => $entry->id, type => "entry" },
        });
    }

}

sub update_stats {
    my $self        = shift;
    my $event       = shift;
    my $entries     = shift;
    my $mongo       = $self->env->mongo;
    my $now         = DateTime->now;
    my $col         = $mongo->collection('Stat');

    $col->increment($now, "event created", 1);
    $col->increment($now, "entry created", scalar(@$entries));
}

sub save_attachments {
    my $self        = shift;
    my $event       = shift;
    my $attachments = shift;
    my $firstentry   = shift;
    my @entries     = ();
    my $log         = $self->env->log;

    my @keys = keys %{$attachments};
    my $count   = scalar(@keys);

    $log->debug("save $count attachments");

    foreach my $filename (@keys) {
        $log->debug("working on file $filename");

        my $content = $attachments->{$filename}->{content};
        my $mime    = $attachments->{$filename}->{mime};

        if ($mime eq "message/rfc822" ) {
            $log->debug("attachment is a rfc822 email");
            my $entry = $self->create_rfc822_entry(
                $event, $content, $firstentry
            );
            if ( $entry ) {
                push @entries, $entry;
            }
            next;
        }

        # email attachments suck.  could be anything. 
        # assume that it is a file and save it, create a file obj to track
        # and create an entry

        my $entry   = $self->create_file_entry(
            $event,
            $filename,
            $mime,
            $content
        );

        if ( $entry ) {
            push @entries, $entry;
        }
    }
    return wantarray ? @entries : \@entries;
}

sub create_rfc822_entry {
    my $self    = shift;
    my $event   = shift;
    my $content = shift;
    my $firstentry  = shift;
    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;

    $log->debug("rfc822 entry creation!");
    $log->debug("first entry is ".$firstentry->id);

    my $entry_request = {
        target_type => 'event',
        target_id   => $event->id,
        parent      => $firstentry->id,
        body        => $content,
        owner       => 'scot-admin',
    };
    my $entry = $mongo->collection('Entry')->create($entry_request);
    return $entry;
}

sub create_file_entry {
    my $self    = shift;
    my $event   = shift;
    my $filename = shift;
    my $mime    = shift;
    my $content = shift;
    my $log     = $self->env->log;

    $log->debug("create file entry");

    # 1. where to store contents
    my $target_dir = $self->build_target_dir($event);

    # 2.  write contents to filesystem

    $log->debug("Content size is ".length($content));

    if (my $fqn = $self->write_attachment($target_dir, $filename, $content) ){
        $log->debug("Wrote contents to $fqn");

        # 3. build File object
        my $fileobj = $self->build_file_obj($event, $target_dir, $filename, $fqn);
        if (! defined $fileobj ) {
            $log->error("Failed to create File OBJ!");
            return undef;
        }

        # 4. create entry to hold file obj

        my $entry = $self->build_entry_obj($fileobj,$event);
        if ( ! defined $entry ) {
            $log->error("Failed to create Entry!");
            return undef;
        }
        return $entry;
    }
    else {
        $log->error("FAILED to write $filename contents!");
        return undef;
    }
}

sub build_target_dir {
    my $self    = shift;
    my $event   = shift;
    my $name    = shift;
    my $base    = $self->env->file_store_root;
    my $dt      = DateTime->from_epoch({ epoch => $event->created });
    my $year    = $dt->year;
    my $id      = $event->id;
    return join('/', $base, $year, "event", $id);
}

sub write_attachment {
    my $self    = shift;
    my $dir     = shift;
    my $name    = shift;
    my $content = shift;
    my $log     = $self->env->log;

    # NEED TO CHECK IF DIR exist and if not create it
    if (! -d $dir) {
        make_path($dir);
    }

    my $target_file = join('/', $dir, $name);

    $log->debug("write attachment $target_file");
    my $fqn = try {
        open my $out, ">", $target_file;
        print $out $content;
        close $out;
        return $target_file;
    }
    catch {
        $log->error("Failed to write file $target_file!: $_");
        return undef;
    };
    return $fqn;
}

sub build_file_obj {
    my $self    = shift;
    my $event   = shift;
    my $dir     = shift;
    my $name    = shift;
    my $fqn     = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    $log->debug("build_file_obj");

    my $props   = $self->get_file_props($fqn);

    my $data    = {
        filename    => $name,
        directory   => $dir,
        size        => $props->{size},
        md5         => $props->{md5},
        sha1        => $props->{sha1},
        sha256      => $props->{sha256},
        groups      => $event->groups,
        target      =>  {type => 'event', id => $event->id, },
        entry_target => {type => 'event', id => $event->id, },
    };

    my $file = $mongo->collection('File')->create($data);

    if ( ! defined $file ) {
        $log->error("Failed to create file object!");
        return undef;
    }
    return $file;
}

sub get_file_props {
    my $self    = shift;
    my $fqn     = shift;
    my $log     = $self->env->log;

    $log->debug("get_file_props");

    my $content = read_file($fqn);
    my $size    = (stat $fqn)[7];
    my $hashes  = $self->hash_file($content);

    return {
        size    => $size,
        md5     => $hashes->{md5},
        sha1    => $hashes->{sha1},
        sha256  => $hashes->{sha256},
    };
}

sub build_entry_obj {
    my $self    = shift;
    my $fileobj = shift;
    my $event   = shift;
    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;

    $log->debug("build_entry_obj");

    my $id      = $event->id;
    my $col     = $mongo->collection('Entry');
    my $entry   = $col->create_from_file_upload($fileobj, 0, 'event', $id);

    if ( ! defined $entry ) {
        $log->error("Failed to create error!");
        return undef;
    }
    return $entry;
}

sub hash_file {
    my $self    = shift;
    my $data    = shift;
    return {
        md5 => md5_hex($data),
        sha1 => sha1_hex($data),
        sha256 => sha256_hex($data),
    };
}
                    
1;
