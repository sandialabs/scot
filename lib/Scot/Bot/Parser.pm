package Scot::Bot::Parser;

use lib '../../../lib';
use strict;
use warnings;
use Courriel;
use Scot::Util::Redis3;
use Data::Dumper;
use Scot::Env;
use Scot::Util::Mongo;
use Scot::Model::Alertgroup;
use Scot::Model::Alert;
use HTML::FromText;
use v5.10;

use Moose;

has env => (
    is          => 'ro', 
    isa         => 'Scot::Env',
    required    => 1,  
);

has imap  => (
    is          => 'ro',
    isa         => 'Scot::Util::Imap',
    required    => 1,
);

has 'message_href'   => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
);
    
has 'interactive'   => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => "_get_interactive_setting",
);

# need to refactor this
has special_subjects => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    builder     => '_build_subjects',
);

sub _build_subjects {
    my $self    = shift;
    my @irtpagers   = qw(
    ); # list of email addrs that will go to paging system
    my $href    = {
       'MESSAGEKEY'   => {
            message => "A specieal Alert has been received.",
            pagers  => \@irtpagers,
        },
    };
    return $href;
}

sub _get_interactive_setting {
    my $self    = shift;
    return $self->env->interactive;
}

sub get_interaction {
    my $self    = shift;
    print "\n Press enter to continue.";
    my $c       = <STDIN>;
}

sub output {
    my $self    = shift;
    my $text    = shift;
    return unless $self->interactive;

    say "-- -- -- -- -- -- -- --";
    say $text;
}

sub log_creation {
    my $self            = shift;
    my $alertgroup_id   = shift;
    my $msg_href        = shift;
    my $subject         = shift;
    my $log             = $self->env->log;
    $log->debug("Creating Alert(s)");
    $log->debug("Alertgroup_id $alertgroup_id");
    $log->debug("From body_html: ".Dumper($msg_href->{body_html}));
    $log->debug("From body_plain: ".Dumper($msg_href->{body_plain}));
    $log->debug("Create Time: ".Dumper($msg_href->{created}));
    $log->debug("Now    Time: ".time());
    $log->debug("Subject is : ".$subject);
}

sub  trim { my $s = shift; return unless $s; $s =~ s/^\s+|\s+$//g; return $s };

sub create_alerts {
    my $self        = shift;
    my $msg_href    = $self->message_href;
    my $log         = $self->env->log;
    my $mongo       = $self->env->mongo;
    my $activemq    = $self->env->activemq;
    my $redis       = $self->env->redis;

    my $alertgroup_id   = $mongo->get_next_id("alertgroups");
    my $subject = $msg_href->{subject};

    unless (defined $subject) {
        $log->error("MISSING SUBJECT!");
        $subject    = "x";
    }

    $self->log_creation($alertgroup_id, $msg_href, $subject);

    my $body = {
        html    => $msg_href->{body_html},
        plain   => $msg_href->{body_plain},
    };

    my $trimmed_html = (defined($body->{'html'})) ? trim($body->{'html'}) : '';
    if(!defined($body->{html}) || $trimmed_html eq '') {
        my $t2h = HTML::FromText->new ({
            paras => 1,   
            blockcode => 1,  
            tables => 1,   
            bullets => 1,   
            numbers => 1,   
            urls => 0,   
            email => 0,   
            bold => 1,   
            underline => 1 });
        $body->{html} = $t2h->parse($body->{plain});
    }

    my ( $alert_aref, $column_aref, $msgid_aref ) = $self->parse_body($body);

    $log->debug("Columns: ".Dumper($column_aref));
    $log->debug("Alerts: " .Dumper($alert_aref));

    my @alert_ids;          # alert_ids created
    my $alertgroup_href;    # href to create the alertgroup

    foreach my $alert_data_href ( @$alert_aref ) {

        my $alert_id;

        my $creation_time;
        if ( $msg_href->{created} ) {
            $creation_time  = $msg_href->{created} + 0;
        }
        else {
            $log->error("Message creation/received time null!. Using now");
            $creation_time  = time();
        }

        my $alert_href  = {
            alertgroup  => $alertgroup_id,
            created     => $creation_time,
            sources     => $msg_href->{sources},
            status      => 'open',
            subject     => $subject,
            data        => $alert_data_href,
            columns     => $column_aref,
            guide_id    => $self->get_guide_id($subject),
            message_id  => $msg_href->{message_id},
        };
        $log->debug("creating alert from ".Dumper($alert_href));
        $alert_href->{'log'} = $log;
        $alert_href->{env} = $self->env;
        if($self->isa('Scot::Bot::Parser::Generic')) {
            $alert_href->{parsed} = 0;
         }
        
        my $alert_obj   = Scot::Model::Alert->new($alert_href);
        $alert_obj->searchtext($alert_obj->build_search_text());
        $alert_obj->add_historical_record({
            who     => $msg_href->{from},
            what    => "created alert via email",
            when    => time(),
        });
        $alert_id       = $mongo->create_document($alert_obj);

        unless ($alert_id) {
            $log->error("FAILED TO CREATE alert FROM ".Dumper($alert_obj->as_hash));
        }
        if ($self->interactive) {
            printf "   Saving Alert %6d to db.\n", $alert_id;
        }

        $alert_obj->alert_id($alert_id);
        $alert_obj->flair_the_data();

        $alertgroup_href    = {
            alertgroup_id   => $alertgroup_id,
            created         => $creation_time,
            guide_id        => $alert_obj->guide_id,
            message_id      => $alert_obj->message_id,
            when            => $alert_obj->when,
            updated         => $alert_obj->updated,
            status          => $alert_obj->status,
            subject         => $subject,
            sources         => $alert_obj->sources,
            events          => [],
            viewcount       => 0,
            body_html       => $body->{html},
            body_plain      => $body->{plain},
            'log'           => $log,
            env      => $self->env,
        };

        # done as a cron job now
        # $alert_obj->update_search_index();

        push @alert_ids, $alert_id;

        my $searchtext  = $alert_obj->searchtext;
        my $id          = $alert_obj->alert_id;

        $redis->add_text_to_search({
            text        => $searchtext,
            id          => $id,
            collection  => "alerts", 
        });
    }

    $alertgroup_href->{alert_ids} = \@alert_ids;

    if($self->isa('Scot::Bot::Parser::Generic')) {
       $alertgroup_href->{parsed} = 0;
    }

    if ($self->interactive) {
        printf "Create Alertgroup: %d\n", $alertgroup_id;
    }
    if ( $alertgroup_href->{alertgroup_id} ) {
        my $alertgroup_obj = Scot::Model::Alertgroup->new($alertgroup_href);
        my $ag_id = $mongo->create_document($alertgroup_obj, -1);
        unless (defined $ag_id) {
            $log->error("FAILED to CREATE alertgroup from ".Dumper($alertgroup_href));
        }
        $activemq->send("activity", {
            type    => "alertgroup",
            action  => "creation",
            id      => $alertgroup_href->{alertgroup_id},
            alerts  => \@alert_ids,
        });
    }

    $self->add_message_id_entities(
        $msgid_aref, 
        \@alert_ids, 
        $alertgroup_href->{alertgroup_id});

    $self->check_for_paging_alert($alertgroup_href);
}

sub add_message_id_entities {
    my $self            = shift;
    my $msgid_aref      = shift;
    my $alert_ids_aref  = shift;
    my $alertgroup_id   = shift;

    my $log         = $self->env->log;
    my $mongo       = $self->env->mongo;

    foreach my $msgid (@$msgid_aref) {
        if ( $mongo->update_documents({
            collection  => 'entities',
            match_href  => { value => $msgid },
            data_href   => {
                '$set'  => { entity_type => 'message_id'},
                '$push' => {
                    alerts      => { '$each' => $alert_ids_aref },
                    alertgroups => $alertgroup_id,
                },
            },
            opts_href   => { multiple => 1, upsert => 1, safe => 1}
        })) {
            $log->debug("Created/Updated entity msg_id $msgid");
        }
        else {
            $log->error("Error updating msg_id $msgid");
        }
    }
}


sub check_for_paging_alert {
    my $self    = shift;
    my $href    = shift;

    my $subject = $href->{subject};
    my $agid    = $href->{alertgroup_id};

    my $target_subjects_href    = $self->special_subjects;

    foreach my $target_subject (keys %{$target_subjects_href}) {

        if ($subject =~ /$target_subject/i) {
            $self->send_pager_notification($subject, $agid, $target_subjects_href->{$target_subject});
        }
    }
}

sub send_pager_notification {
    my $self        = shift;
    my $subject     = shift;
    my $agid        = shift;
    my $href        = shift;
    my $pagers_aref = $href->{pagers};
    my $message     = $href->{message};
    my $env         = $self->env;
    my $mprefs      = $env->{mailer_prefs};

    my $mailer  = new Net::SMTP('IP_FOR_OUTGOING_EMAIL');
    $mailer->mail($mprefs->{from_email_acct});
    $mailer->recipient(@{$pagers_aref});
    $mailer->data;
    $mailer->datasend("To: ". join(', ', @{$pagers_aref})."\n");
    $mailer->datasend("From: ". $mprefs->{mailer_from}."\n");
    $mailer->datasend("Subject: $subject\n\n");
    $mailer->datasend("$message.\nSee Alertgroup $agid\n");
    $mailer->datasend($mprefs->{urlstem}."/#/alert/group/$agid\n");
    $mailer->dataend;
    $mailer->quit;
}

sub get_guide_id {
    my $self    = shift;
    my $subject = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    $log->debug("Looking up Guide ID for $subject");

    $subject    =~ s/FW:[ ]*//;

    my $object  = $mongo->read_one_document({
        collection  => "guides",
        match_ref   => { guide => $subject },
    });

    if ( $object ) {
        return $object->guide_id;
    }

    $log->debug("No existing guide, creating...");

    my $guide   = Scot::Model::Guide->new({
        guide   => $subject,
    });

    $log->debug("attempting to save guide");

    if (defined $guide) {
        my $guide_id    = $mongo->create_document($guide);
        return $guide_id;
    } 
    else {
        $log->error("didnt create guide!");
    }
}

1;
