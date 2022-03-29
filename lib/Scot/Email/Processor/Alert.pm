package Scot::Email::Processor::Alert;

use strict;
use warnings;

use Data::Dumper;
use Module::Runtime qw(require_module);
use Try::Tiny;
use Mojo::JSON qw(encode_json);
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

has msvlog => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
    default => '/var/log/scot/msv.log',
);

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

    my $agroup  = $self->create_alertgroup($json);

    if ( defined $agroup and ref($agroup) eq "Scot::Model::Alertgroup" ) {
        $log->debug("Success creating alergroup: ".$agroup->id);
        return 1;
    }

    $log->error("Failed to create Alertgroup!");
    $log->trace({filter=>\&Dumper, value=>$msg});
    return undef;

}

sub is_health_check {
    my $self    = shift;
    my $msg     = shift;
    my $subject = $msg->{subject};
    return ($subject =~ /Scot Health Check/i);
}

sub select_parser {
    my $self    = shift;
    my $msg     = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $subject = $msg->{subject};
    my $from    = $msg->{from};
    my $class;

    if ( $subject =~ /splunk alert/i or $from =~ /splunk/i ) {
        $class  = "Scot::Email::Parser::Splunk";
    }
    else {
        $class  = "Scot::Email::Parser::GenericAlert";
    }
    $log->debug("requiring $class to parse message...");
    require_module($class);
    my $instance = $class->new({env => $env});
    return $instance;
}

sub already_processed {
    my $self    = shift;
    my $msg     = shift;
    my $mid     = $msg->{message_id};

    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Alertgroup');
    my $agroup  = $col->get_by_msgid($mid);
    return defined $agroup;
}

sub create_alertgroup {
    my $self    = shift;
    my $json    = shift;

    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Alertgroup');

    $log->debug("creating alertgroup");

    if ( $self->dry_run ) {
        $log->debug("Would have created Alertgroup(s) from: ",
                    {filter => \&Dumper, value => $json});
        return;
    }


    my @agroups = ();
    $self->filter_msv_alert($json);
    try {
        @agroups = $col->api_create({
            request => { json => $json }
        });
    }
    catch {
        $log->error("ERROR Creating Alertgroup: $_");
        $log->error({filter=>\&Dumper, value => $json});
        $log->logdie("what now?");
    };
    my $created = scalar(@agroups);
    $log->debug("Created $created Alertgroups");

    if ( $created > 0 ) {
        $self->scot_housekeeping(@agroups);
    }
}

sub filter_msv_alert {
    my $self    = shift;
    my $json    = shift;
    
    # look for ipaddrs and hostnames from MSV 
    # if present, write row to logfile
    # and remove it from $json so it wont' be 
    # created 
    my @newdata = ();
    my $data    = $json->{data};

    foreach my $row (@$data) {
        if ( $self->scan_for_msv($row) ) {
            $self->write_row($row);
        }
        else {
            push @newdata, $row;
        }
    }
    $json->{data} = \@newdata;
}

sub scan_for_msv {
    my $self    = shift;
    my $row     = shift;
    my $filters = $self->env->msv_filters;
    my $log     = $self->env->log;
    my $rowcat  = $self->concat_row_cells($row);
    my $timer   = $self->env->get_timer("msv_scan");

    # concat row values into single string
    # scan that string for substrings that match items in msv_filters

    foreach my $ftype (keys %$filters) {
        my $items   = $filters->{$ftype};
        foreach my $item (@$items) {
            if ( $rowcat =~ /\b$item\b/i ) {
                my $elapsed = &$timer;
                $log->warn("MSV: Found $item of type $ftype in $elapsed secs in row $rowcat");
                return 1;
            }
        }
    }
    my $elapsed = &$timer;
    $log->debug("No MSV content detected. scan time = $elapsed seconds.");
    return undef;
}

sub concat_row_cells {
    my $self    = shift;
    my $row     = shift;
    my $concat  = '';
    foreach my $col (keys %$row) {
        my $cell    = $row->{$col};
        if (ref($cell) eq 'ARRAY') {
            $concat .= ' '.join(' ', @$cell);
        }
        else {
            $concat .= ' '.$cell;
        }
    }
    return $concat;
}

sub write_row {
    my $self    = shift;
    my $row     = shift;
    my $msvlog  = $self->msvlog;

    open my $fh, ">>", $msvlog;
    print $fh, encode_json($row)."\n";
    close $fh;
}

sub scot_housekeeping {
    my $self    = shift;
    my @ag      = @_;
    my $env     = $self->env;
    my $mq      = $env->mq;
    
    foreach my $a (@ag) {
        $self->notify_flair_engine($a);
        $self->begin_history($a);
        $self->update_stats($a);
    }
}

sub notify_flair_engine {
    my $self        = shift;
    my $alertgroup  = shift;
    my $mq          = $self->env->mq;
    my $message     = {
        action  => "created",
        data    => {
            type    => "alertgroup",
            id      => $alertgroup->id,
            who     => "scot-alerts",
        }
    };
    $mq->send("/queue/flair", $message);
    $mq->send("/topic/scot", $message);
}

sub begin_history {
    my $self        = shift;
    my $alertgroup  = shift;
    my $mongo       = $self->env->mongo;

    $mongo->collection('History')->add_history_entry({
        who     => 'scot-alerts',
        what    => 'created alertgroup',
        when    => time(),
        target  => { id => $alertgroup->id, type => "alertgroup" },
    });
}

sub update_stats {
    my $self        = shift;
    my $alertgroup  = shift;
    my $mongo       = $self->env->mongo;
    my $now         = DateTime->now;
    my $col         = $mongo->collection('Stat');

    $col->increment($now, "alertgroup created", 1);
    $col->increment($now, "alerts created", $alertgroup->alert_count);
}


1;


