package Scot::Email::Processor;

use lib '../../../lib';
use strict;
use warnings;

=head1 Processor.pm

Future replacement for Mail.pm EmailApi2.pm, etc.

Now with a config entry, we can add an email inbox to monitor/fetch from
The entry will tell this program what queue to place the message on.
Responders will be listening to the queues and perform appropriat processing

=cut

use Data::Dumper;
use DateTime;
use Try::Tiny;
use Scot::Env;
use Scot::Email::Imap;
use Scot::Email::Imap::Cursor;
use HTML::TreeBuilder;
use Parallel::ForkManager;
use Module::Runtime qw(require_module compose_module_name);

use Moose;
extends 'Scot::App';

has max_processes => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_build_max_processes',
);

sub _build_max_processes {
    my $self    = shift;
    my $attr    = "max_processes";
    my $default = 0;
    my $envname = "scot_app_mail_max_processes";
    return $self->get_config_value($attr, $default, $envname);
}

has interactive => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_interactive',
);

sub _build_interactive {
    my $self    = shift;
    my $attr    = "interactive";
    my $default = "no";
    my $envname = "scot_app_mail_interactive";
    return $self->get_config_value($attr, $default, $envname);
}

has verbose => (
    is      => 'rw',
    isa     => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_build_verbose',
);

sub _build_verbose {
    my $self    = shift;
    my $attr    = "verbose";
    my $default = 0;
    my $envname = "scot_app_mail_verbose";
    return $self->get_config_value($attr, $default, $envname);
}

has mailboxes => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_mailboxes',
);

sub _build_mailboxes {
    my $self    = shift;
    my $attr    = "mailboxes",
    my $default = [
        # {
        #   description => "alert_inbox",
        #   mailserver  => "mail.domain.com",
        #   port        => 993,
        #   username    => "mailbox_username",
        #   password    => "password_for_user",
        #   inbox       => "INBOX", # usually
        #   ssl_opts    => [ 
        #       SSL_verify_mode, 1
        #   ],
        #  queue => "/queue/queue_name_that_will_process_message",
        # },
    ];
    my $envname = "scot_app_mail_mailboxes";
    return $self->get_config_value($attr, $default, $envname);
}

sub run {
    my $self    = shift;
    my $log     = $self->log;

    my $pm  = Parallel::ForkManager->new($self->max_processes);

    MBOX:
    foreach my $mbox (@{$self->mailboxes}) {

        if ( $self->mailbox_not_active($mbox) ) {
            $log->warn("MBOX $mbox->{name} is NOT Active.  Skipping.");
            next MBOX;
        }

        # fork and process this mbox
        my $pid = $pm->start and next;

        my $description = $mbox->{description} // 'no_desc';

        $log->debug("Fetching $description");
        my @messages = $self->fetch_email($mbox);

        $log->debug("Retrieved ".scalar(@messages)." email messages");
        $self->queue_processing($mbox, @messages);

        $pm->finish;
    }

    $pm->wait_all_children;
}

sub mailbox_not_active {
    my $self    = shift;
    my $mbox    = shift;
    return (!defined $mbox->{active} or $mbox->{active} != 1);
}

sub dump_messages {
    my $self    = shift;
    my $log     = shift;
    
    MBOX:
    foreach my $mbox (@{$self->mailboxes}) {
        if ($self->mailbox_not_active($mbox)) {
            $log->warn("MBOX $mbox->{name} is NOT Active.  Skipping.");
            next MBOX;
        }
        $log->debug("Dumping $mbox->{description}...");
        $self->dump_inbox($mbox);
    }
}

sub get_imap_client {
    my $self    = shift;
    my $mbox    = shift;
    my $config  = {
        mailbox     => $mbox->{mailbox},
        hostname    => $mbox->{hostname},
        port        => $mbox->{port},
        username    => $mbox->{username},
        password    => $mbox->{password},
        ssl         => $mbox->{ssl},
        uid         => 1,
        ignore_size_errors => 1,
        env         => $self->env,
        test_mode   => $mbox->{test},
        permitted_senders   => $mbox->{permitted_senders},
    };

    $log->trace("Imap Config ",{filter=>\&Dumper, value=>$config});
    $log->debug("Attempting to fetch $mbox->{username} $mbox->{mailbox}");

    my $imap            = Scot::Email::Imap->new($config);
    return $imap;
}

sub dump_inbox {
    my $self    = shift;
    my $mbox    = shift;
    my $imap    = $self->get_imap_client($mbox);
    $imap->dump_imap_inbox;
}

sub fetch_email {
    my $self    = shift;
    my $mbox    = shift;
    my @messages    = ();
    my $log     = $self->log;

    my $imap            = $self->get_imap_client($mbox);
    my $unseen_cursor   = $imap->get_unseen_cursor;
    my $msg_count       = $unseen_cursor->count;

    $log->debug("Retrieved $msg_count messages for $mbox->{username} mailbox");
    while ( my $uid = $unseen_cursor->next ) {
        my $message = $imap->get_message($uid);
        push @messages, $message if defined $message;
    }
    return wantarray ? @messages : \@messages;
}

sub queue_processing {
    my $self    = shift;
    my $mbox    = shift;
    my @messages    = @_;
    my $mq          = $self->env->mq;
    my $responder   = $mbox->{responder};
    my $queue       = $self->get_queue($responder);
    my $log         = $self->log;

    $log->debug("Sending messages to processing queues");

    foreach my $message (@messages) {
        $log->debug("$queue => to: ".$message->{to}." Subject: ".$message->{subject});
        $mq->send($queue, {
            email => $message
        });
    }
}

sub get_queue {
    my $self    = shift;
    my $resp    = shift;
    my $env     = $self->env;

    my $resp_data = $env->responders->{$resp};
    my $queue     = $resp_data->{queue};

    if ( ! defined $queue ) {
        $self->env->log->error("QUEUE NOT DEFINED!: ",
                               {filter=>\&Dumper, value=> $resp_data});
    }

    return $queue;
}

1;
