package Scot::App::Email;

use lib '../../../lib';
use lib '/opt/scot/lib';
use strict;
use warnings;

use Data::Dumper;
use DateTime;
use Try::Tiny;
use Mojo::UserAgent;
use Scot::Env;
use Scot::Util::Imap;
use HTML::TreeBuilder;
use Parallel::ForkManager;
use Module::Runtime qw(require_module compose_module_name);
use Log::Log4perl::Level;

use Moose;
extends 'Scot::App';


has imap_config    => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_imap_config',
);

sub _build_imap {
    my $self    = shift;
    my $attr    = "imap_config",
    my $default = {
        mailbox     => 'INBOX',
        hostname    => 'mail.sandia.gov',
        port        => 993,
        uid         => 1,
        ignore_size_errors  => 1,
    };
    my $envname = "scot_app_mail_imap_config";
    return $self->get_config_value($attr, $default, $envname);
}

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

has inboxes => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    builder     => '_build_inboxes',
);

sub _build_inboxes {
    my $self    = shift;
    my $attr    = "inboxes",
    my $default = [
        { inbox => "alerts", account => "scot-alerts", password => "changeme",  },
    ];
    my $envname = "scot_app_mail_inboxes";
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

has approved_accounts   => (
    is      => 'rw',
    isa     => 'ArrayRef',
    required=> 1,
    lazy    => 1,
    builder => "_get_approved_accounts",
);

sub _get_approved_accounts {
    my $self    = shift;
    my $attr    = "approved_accounts";
    my $default = [ ];
    my $envname = "scot_app_mail_approved_accounts";
    return $self->get_config_value($attr, $default, $envname);
}

has approved_alert_domains  => (
    is      => 'rw',
    isa     => 'ArrayRef',
    required=> 1,
    lazy    => 1,
    builder => "_get_approved_alert_domains",
);

sub _get_approved_alert_domains {
    my $self    = shift;
    my $attr    = "approved_alert_domains";
    my $default = [ ];
    my $envname = "scot_app_mail_approved_alert_domains";
    return $self->get_config_value($attr, $default, $envname);
}

has fetch_mode  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_fetch_mode',
);

sub _build_fetch_mode {
    my $self    = shift;
    my $attr    = "fetch_mode";
    my $default = 'unseen';
    my $envname = "scot_app_mail_fetch_mode";
    return $self->get_config_value($attr, $default, $envname);
}

has since       => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_since',
);

sub _build_since {
    my $self    = shift;
    my $attr    = "since";
    my $default = { hour => 2};
    my $envname = "scot_app_since";
    return $self->get_config_value($attr, $default, $envname);
}

has parsermap   => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => 'load_parsers',
);

sub load_parsers  {
    my $self    = shift;
    my $log     = $self->log;

    my $parser_dir  = $self->env->parser_dir //
                      "/opt/scot/lib/Scot/Parser";
    try {
        opendir(DIR, $parser_dir);
    }
    catch {
        $log->warn("No Parsers in $parser_dir!");
        return undef;
    };
    my %pmap    = ();
    while ( my $filename = readdir(DIR) ) {
        next if ( $filename =~ /^\.+$/ );
        next if ( $filename =~ /.*swp/ );
        $log->debug("requiring module $filename");
        $filename =~ m/^([A-Za-z0-9]+)\.pm$/;
        my $rootname = $1;
        my $attrname = lc($rootname);
        my $class    = "Scot::Parser::$rootname";
        require_module($class);
        $pmap{$attrname} = $class->new({ log => $self->log });
    }
    return wantarray ? %pmap : \%pmap;
}

sub mark_all_read {
    my $self    = shift;
    my $log     = $self->log;
    my $imap    = $self->imap;

    $log->trace("Marking all messages as Seen");
    my $cursor  = $imap->get_unseen_cursor;
    while ( my $uid = $cursor->next ) {
        $imap->see($uid);
    }
}

sub mark_some_unread {
    my $self    = shift;
    my $since   = shift;
    my $log     = $self->log;
    my $imap    = $self->imap;

    my $cursor  = $imap->get_since_cursor($since);
    while ( my $uid = $cursor->next ) {
        $imap->mark_uid_unseen($uid);
    }
}

sub run {
    my $self    = shift;
    my $log     = $self->log;
    
    $log->debug("Beginning Email Processing Daemon");
    print "SCOT Email Processing...\n" if ( $self->interactive eq "yes");

    my $interval    = 60;   # seconds

    while (1) {
        try {
            $self->process_inboxes;
        }
        catch {
            $log->error("Processing Error: $_");
        };
        sleep $interval;
    }
}

sub process_inboxes {
    my $self    = shift;
    my $log     = $self->log;
    my $inboxes = $self->inboxes;

    foreach my $inbox_href (@$inboxes) {
        my $type    = delete $inbox_href->{type};       # alert, event, ...
        $log->debug("building imap connection to $type inbox...");
        my $imap    = $self->build_imap($inbox_href);
        $self->process_inbox($type, $imap);
    }
}

sub build_imap {
    my $self    = shift;
    my $cfg     = shift;
    my $imap    = Scot::Util::Imap->new($cfg);
    return $imap;
}

sub process_inbox {
    my $self    = shift;
    my $type    = shift;
    my $imap    = shift;
    my $log     = $self->log;

    $log->debug("processing inbox $type...");
    my $cursor  = $self->fetch_messages($imap);

    my $msg_count   = $cursor->count;

    if ( $msg_count < 1 ) {
        $log->warn("no meessages returned from IMAP server");
        die "no messages returned from IMAP server";
    }

    my $pm  = Parallel::ForkManager->new($self->max_processes);
    my $pcount  = 0;

    MESSAGE:
    while ( my $uid = $cursor->next ) {
        my $msg_href    = $imap->get_message($uid);
        my $pid         = $pm->start and next;
        my $status      = $self->process_message($imap, $type, $msg_href);
        if ( $status eq "unapproved" ) {
            $log->error("Unapproved Sender: ", { filter=>\&Dumper, value=>$msg_href});    
        }
        elsif ( $status eq "healthcheck" ) {
            $log->error("Health Check Received");    
        }
        elsif ( $status eq "alreadyprocessed" ) {
            $log->error("Message Already Processed by SCOT" );    
        }
        elsif ( $status eq "postfailed" ) {
            $log->error("POST to SCOT failed: ", { filter=>\&Dumper, value=>$msg_href});    
        }

        $pcount++;
        $log->trace("[UID $uid] Child process $pid finishes");

        if ( $self->env->leave_unseen ) {
            print "---- marked as unseen\n" if ($self->verbose);
            $imap->mark_uid_unseen($uid);
        }

        $pm->finish;

        if ( $self->interactive eq "yes" ) {
            print "Press ENTER to continue, or \"off\" to turn of interactive";
            my $resp = <STDIN>;
            if ( $resp =~ /off/i ) {
                $self->interactive("no");
            }
        }

    }
    $pm->wait_all_children;
}

sub fetch_messages {
    my $self    = shift;
    my $imap    = shift;
    my $log     = $self->log;
    if ( $self->fetch_mode eq "unseen" ) {
        $log->debug("requesting unseen messages...");
        return $imap->get_unseen_cursor;
    }
    $log->debug("requesting messages since ",{filter=>\&Dumper, value=> $self->since});
    return $imap->get_since_cursor($self->since);
}

sub process_message {
    my $self        = shift;
    my $imap        = shift;
    my $type        = shift;
    my $msg_href    = shift;
    my $log         = $self->log;

    my $msg_id      = $msg_href->{message_id};
    my $received    = DateTime->from_epoch( epoch => $msg_href->{when} );

    if ( $self->unapproved_sender($msg_href) ) {
        $log->error("Unapproved_sender! Rejected message from ".$msg_href->{from});
        $imap->delete_message($msg_href->{imap_uid});
        return "unapproved";
    }

    if ( $self->is_health_check($msg_href) ) {
        $log->warn("Health check received.  skipping...");
        return "healthcheck";
    }

    if ( $self->already_processed($type, $msg_id)) {
        $log->warn("Message id: $msg_id already processed");
        $imap->see($msg_href->{imap_uid});
        return "alreadyprocessed";
    }

    my $parsed_data = $self->parse_message($type, $msg_href);

    if ( ! defined $parsed_data ) {
        $log->error("Failed to Parse Message!");
        return "failedparse";
    }

    my @results = $self->submit_parsed($type,$parsed_data);

    if ( scalar(@results) < 1 ) {
        $log->error("Failed to post data.");
        return "postfailed";
    }

    foreach my $result (@results) {
        if ( $result->{status} eq "ok" ) {
            $log->debug("created $type ".$result->{id});
            $imap->see($msg_href->{imap_uid});
        }
        else {
            $log->debug("Failed to create $type from message ".$msg_href->{imap_uid});
            $imap->mark_uid_unseen($msg_href->{imap_uid});
        }
    }
    return 1;
}

sub unapproved_sender {
    my $self        = shift;
    my $msg_href    = shift;
    my $log         = $self->log;
    my $this_sender = $msg_href->{from};
    $this_sender    =~ s/<(.*)>/$1/;

    $log->debug("checking if $this_sender is approved");

    if ( grep { $_ eq $this_sender } @{$self->approved_accounts} ) {
        $log->debug("$this_sender is among the approved accounts.");
        return undef;
    }

    my $senders_domain = (split(/\@/, $this_sender))[1];
    $log->debug("checking if $senders_domain is an approved domain");

    if ( grep { /$senders_domain/ } @{$self->approved_domains} ) {
        $log->debug("$senders_domain is among the approved domains.");
        return undef;
    }

    $log->error("unapproved sender: $this_sender");
    return 1;
}

sub is_health_check {
    my $self        = shift;
    my $msg_href    = shift;
    my $log         = $self->log;

    $log->debug("is this a health check message?");

    my $subject = $msg_href->{subject};
    if ( $subject =~ /SCOT Health Check/i ) {
        $log->debug("it is. moving on.");
        return 1;
    }
    return undef;
}

sub already_processed {
    my $self        = shift;
    my $type        = shift;
    my $uid         = shift;
    my $log         = $self->log;
    my $env         = $self->env;
    my $mongo       = $env->mongo;

    my $query   = ($type eq "alertgroup") ? 
                  { message_id  => $uid } :
                  { id => $uid };
    my $obj = $mongo->collection(ucfirst($type))->find_one($query);
    if ( defined $obj ) {
        $log->warn("Message $uid already processed");
        return 1;
    }
    return undef;
}

sub parse_message {
    my $self        = shift;
    my $type        = shift;
    my $msg_href    = shift;
    my $log         = $self->log;

    my $parser  = $self->get_parser($msg_href);
    my $data    = $parser->parse_message($msg_href);

    $data->{message_id} = $msg_href->{message_id};
    $data->{subject}    = $msg_href->{subject} if ( ! defined $data->{subject} );
    $data->{sources}    = [ $parser->get_sourcename ];
    $data->{created}    = $msg_href->{when};

    return $data;
}

sub submit_parsed {
    my $self        = shift;
    my $type        = shift;
    my $data        = shift;
    my $log         = $self->log;
    my $mongo       = $self->env->mongo;
    my @responses   = ();

    if ( $type eq  "alertgroup" ) {
        my $agcol   = $mongo->collection('Alertgroup');
        my @agobjs  = $agcol->api_create({
            request => { json   => $data }
        });

        foreach my $ag (@agobjs) {

            $self->env->mq->send("/topic/scot", {
                action  => "created",
                data    => {
                    type    => "alertgroup",
                    id      => $ag->id,
                    who     => "scot-alerts",
                }
            });
            my $response = { 
                status  => 'ok',
                thing   => 'alertgroup',
                id      => $ag->id,
            };
            push @responses, $response;
            $mongo->collection('History')->add_history_entry({
                who     => "scot-alerts",
                what    => "created alertgroup",
                when    => time(),
                target  => {
                    id      => $ag->id,
                    type    => 'alertgroup',
                },
            });
            my $now = DateTime->now;
            $mongo->collection('Stat')->increment($now,
                                                "alertgroups created",
                                                1);
            $mongo->collection('Stat')->increment($now,
                                                "alerts created",
                                                $ag->alert_count);
        }
    }
    else {
        my $subject = $data->{subject};
        my ($command, $remainder) = split(/\)/,$subject);
        my $thing;
    }

}








    


1;
