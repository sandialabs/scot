package Scot::Bot::ForkAlerts;
use lib '../../../lib';
use strict;
use warnings;
use v5.10;

use Scot::Env;
use Scot::Util::Imap;
use Scot::Util::Mongo;
# use Scot::Util::Phantom;
use Scot::Util::EntityExtractor;
use Scot::Util::ActiveMQ;
use Mail::IMAPClient;

use Scot::Model::Entry;
use Scot::Model::Alert;

use Scot::Bot::Parser::Generic;
use Scot::Bot::Parser::Splunk;
use Scot::Bot::Parser::Sophos;
use Scot::Bot::Parser::Sourcefire;
use Scot::Bot::Parser::Forefront;
use Scot::Bot::Parser::FireEye;
use Scot::Bot::Parser::Js;

use Readonly;
Readonly my $EMPTYLINE      => qr/^\s*$/;
Readonly my $MESSAGE_ID_FMT => qr/\A\d+\z/;

use Moose;
extends 'Scot::Bot';
use namespace::autoclean;
use Data::Dumper;
use Parallel::ForkManager;

$| = 1; #don't buffer output

has 'env'  => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
);

has imap  => (
    is          => 'ro',
    isa         => 'Scot::Util::Imap',
    required    => 1,
    lazy        => 1,
    builder     => '_get_imap',
);

sub _get_imap {
    my $self    = shift;
    return $self->env->imap;
}

sub run  {
    my $self        = shift;
    my $opts_href   = shift;
    my $env         = $self->env;
    my $imap        = $self->imap;
    my $log         = $env->log;
    my $status      = {};
    my $scot_mode   = $env->config->{globals}->{scot_mode};
    my $interactive;

    my $messages_aref   = $imap->get_messages_aref($opts_href);
    my $pause           = 1;
    my $reprocess       = $opts_href->{reprocess};

    my $message_count   = scalar(@{$messages_aref});
    my $counter         = 0;

    my $last_health_check   = $self->get_last_health_check;

    my $taskmanager = Parallel::ForkManager->new(10);
    my @tasks;

    MESSAGE:
    foreach my $message_id ( @$messages_aref ) {

        my $header_msg_id   = $self->get_header_msg_id($message_id);
        next unless $header_msg_id;

        if ( $interactive ) {
            printf "Message %4d of %4d : ", $counter, $message_count;
        }

        if ( $self->already_processed($header_msg_id, $reprocess) ) {
            if ( $interactive ) {
                print "processed.\n";
            }
            $log->debug("$header_msg_id already processed");
            next MESSAGE;
        }

        my $href        = $imap->get_message($message_id, $header_msg_id);
        my $parserclass = $href->{parser};
        my $data_href   = $href->{msg_href};

        unless ( $imap->permitted_sender($data_href) ) {
            next MESSAGE;
        }
        my $hc_epoch = $self->is_health_check($last_health_check, $data_href);
        if ( $hc_epoch ) {
            $last_health_check = $hc_epoch;
            next MESSAGE;
        }

        my $init_href   = {
            imap            => $imap,
            message_href    => $data_href,
            parserclass     => $parserclass,
        };

        push @tasks, $init_href;
    }

    foreach my $task (@tasks) {

        $log->debug("Submitting TASK ". Dumper($task->{message_href}));

        my $pid = $taskmanager->start and next;

        if ($pid == 0) {
            # need to give each child their own taker instance
            # for the db connections not be closed by each instance
            my $chldenv      = Scot::Env->new(
                config_file => $env->config_file,
                mode        => $env->mode,
            );
            $task->{env} = $chldenv;

            $chldenv->log->debug("Child now working task");

            my $class   = $task->{parserclass};
	    if($class =~ /^js::/) {
                (my $junk, my $parser_id)  = split('::', $class,2);
  	        $task->{'parser_id'} = $parser_id;
                $class="Scot::Bot::Parser::Js";
            }
            my $parser  = $class->new($task);
            $parser->create_alerts();
            $taskmanager->finish;
            exit;
        }
    }
    $taskmanager->wait_all_children;
}

sub get_last_health_check {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;

    my $last_href   = $mongo->read_one_raw({
        collection  => "checkpoints",
        match_ref   => {
            type    => 'health_check',
            name    => 'alert_bot_splunk',
        },
    });

    my $last_epoch;

    if ( defined $last_href  )  {
        $last_epoch = $last_href->{last_checkin};
    }
    return $last_epoch;
}

sub is_health_check {
    my $self            = shift;
    my $last_epoch      = shift;
    my $href            = shift;
    my $env             = $self->env;
    my $log             = $env->log;
    my $mongo           = $self->mongo;
    my $periodicity     = 1320; #22 minutes

    $log->debug("Checking if this is a health heartbeat message");

    my $subject = $href->{subject};

    if ( $subject eq "SCOT-ALERTS HEALTH CHECK DO NOT DISABLE" ) {
        $log->debug("It is!  Updating checkpoints");
        my $created = $href->{created};

        if ( $created > $last_epoch ) {
            $last_epoch = $created;
            $mongo->apply_update({
                collection      => "checkpoints",
                match_ref       => {
                    name    => 'alert_bot_splunk',
                    type    => 'health_check',
                },
                data_ref        => {
                    '$set'  => {
                        last_checkin    => $created,
                        periodicity     => $periodicity,
                    },
                },
            },
            {
                    safe    => 1,
                    upsert  => 1,
            }
            );
        }
        return $last_epoch;
    }
    $log->debug("It is not");
    return undef;
}

sub get_header_msg_id {
    my $self    = shift;
    my $id      = shift;
    my $env  = $self->env;
    my $imap    = $self->imap;
    my $msgid   = $imap->imap_client->get_header($id, "Message-Id");
    $msgid      =~ s/(<.*>)/$1/;
    $env->log->debug("Message-Id of $id is $msgid");
    return $msgid;
}

sub get_interaction {
    print "\n";
    print "Enter the number of messages to process without interaction\n";
    print "(zero means process to end) : ";
    my $c = <STDIN>;
    chomp($c);
    if ( $c !~ /\d+/ ) {
        $c = 1;
    }
    return $c;
}

sub already_processed {
    my $self        = shift;
    my $msgid       = shift;
    my $reprocess   = shift;
    my $env      = $self->env;
    my $log         = $env->log;
    my $mongo       = $env->mongo;

    if ( defined $reprocess and $reprocess ne '' ) {
        return undef;
    }

    my $alertgroup_obj = $mongo->read_one_document({
        collection  => "alertgroups",
        match_ref   => { message_id => $msgid },
    });

    if ( defined $alertgroup_obj ) {
        return 1;
    }
    if ($env->interactive) {
        print "NEW message.\n";
    }
    return undef;
}




1;
