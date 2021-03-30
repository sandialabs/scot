package Scot::Email::Processor::Alert;

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

    my $agroup  = $self->create_alertgroup($json);

    if ( defined $agroup and ref($agroup) eq "Scot::Model::Alertgroup" ) {
        $log->debug("Sucess creating alergroup: ".$agroup->id);
        return;
    }

    $log->error("Failed to create Alertgroup!");
    $log->trace({filter=>\&Dumper, value=>$msg});

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

    my $subject = $msg->{subject};
    my $from    = $msg->{from};
    my $class;

    if ( $subject =~ /splunk alert/i or $from =~ /splunk/i ) {
        $class  = "Scot::Email::Parser::Splunk";
    }
    else {
        $class  = "Scot::Email::Parser::GenericAlert";
    }

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

    my @agroups = $col->api_create({
        request => { json => $json }
    });
    my $created = scalar(@agroups);
    $log->debug("Created $created Alertgroups");

    if ( $created > 0 ) {
        $self->scot_housekeeping(@agroups);
    }
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
    $mq->send("/topic/scot", {
        action  => "created",
        data    => {
            type    => "alertgroup",
            id      => $alertgroup->id,
            who     => "scot-alerts",
        }
    });
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


