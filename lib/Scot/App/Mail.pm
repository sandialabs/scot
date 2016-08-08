package Scot::App::Mail;

use lib '../../../lib';
use Data::Dumper;
use DateTime;
use Try::Tiny;
use Mojo::UserAgent;
use Scot::Env;
use Scot::Util::Imap;
use Scot::Util::Scot;
use HTML::TreeBuilder;
use Parallel::ForkManager;
use strict;
use warnings;
use Module::Runtime qw(require_module compose_module_name);
use Log::Log4perl::Level;

use Moose;
extends 'Scot::App';

has imap    => (
    is          => 'ro',
    isa         => 'Scot::Util::Imap',
    required    => 1,
    lazy        => 1,
    builder     => '_build_imap',
);

sub _build_imap {
    my $self    = shift;
    my $imapcfg = $self->config->{imap};
    $imapcfg->{log} = $self->log;
    return Scot::Util::Imap->new($imapcfg);
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
    if ( $self->config->{max_processes} ) {
        return $self->config->{max_processes};
    }
    return 0;
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
    if ( $self->config->{interactive} ) {
        return $self->config->{interactive};
    }
    return 'no';
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
    if ( $self->config->{verbose} ) {
        return $self->config->{verbose};
    }
    return 0;
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
    my $value   = $self->config->{approved_accounts};
    return $value;
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
    my $value   = $self->config->{approved_alert_domains};
    return $value;
}

has scot => (
    is          => 'ro',
    isa         => 'Scot::Util::Scot',
    required    => 1,
    lazy        => 1,
    builder     => '_build_scot_scot',
);

sub _build_scot_scot {
    my $self    = shift;
    return Scot::Util::Scot->new({
        log         => $self->log,
        servername  => $self->config->{scot}->{servername},
        username    => $self->config->{scot}->{username},
        password    => $self->config->{scot}->{password},
        authtype    => $self->config->{scot}->{authtype},
    });
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
    if ( $self->config->{fetch_mode} ) {
        return $self->config->{fetch_mode};
    }
    return 'unseen';
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
    if ( $self->config->{since} ) {
        return $self->config->{since};
    }
    return { hour => 2 };
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

    my $parser_dir  = $self->config->{parser_dir} //
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
        $log->debug("filename is $filename");
        next if ( $filename =~ /^\.+$/ );
        next if ( $filename =~ /.*swp/ );
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
    my $imap    = $self->imap;

    $log->trace("Beginning Alert Email Processing");

    print "Alert Email Processing...\n" if ( $self->interactive eq "yes" );

    my $cursor;
    if ( $self->fetch_mode eq "unseen" ) {
        $log->debug("requesting unseen message uids");
        $cursor = $imap->get_unseen_cursor;
    }
    else {
        $log->debug("requesting message uids since ",
                    {filter=>\&Dumper,value=>$self->since});
        $cursor = $imap->get_since_cursor($self->since);
    }

    my $msg_to_process = $cursor->count;

    unless ($msg_to_process > 0) {
        $log->warn("No Messages UIDs returned from IMAP server");
        exit 1;
    }

    my $taskmgr = Parallel::ForkManager->new($self->max_processes);

    my $proc_count = 0;

    MESSAGE:
    while ( my $uid = $cursor->next ) {

        if ( $self->verbose ) {
            print "\nMessage: $uid\n";
            print "           $proc_count processed of $msg_to_process\n";
        }

        my $msg_href    = $imap->get_message($uid);

        my $pid = $taskmgr->start and next;

        $log->trace("[UID $uid] Child process $pid begins");

        unless ($self->process_message($msg_href)) {
            $log->error("FAILED to process: ",
                        {filter=>\&Dumper, value=>$msg_href});
        }
        $proc_count++;
        $log->trace("[UID $uid] Child process $pid finishes");
        $taskmgr->finish;

        if ( $self->interactive eq "yes" ) {
            print "Press ENTER to continue, or \"off\" to turn of interactive";
            my $resp = <STDIN>;
            if ( $resp =~ /off/i ) {
                $self->interactive("no");
            }
        }

    }
    $taskmgr->wait_all_children;
}

sub process_message {
    my $self    = shift;
    my $msghref = shift;
    my $log     = $self->log;
    my $scot    = $self->scot;
    my $imap    = $self->imap;

    my $message_id  = $msghref->{message_id};

    my $received    = DateTime->from_epoch(epoch=>$msghref->{when});

    $self->output(
        "---- message_id ". $message_id."\n".
        "---- subject    ". $msghref->{subject}."\n" .
        "---- date       ". $received->ymd . " ".$received->hms."\n"
    );

    # is message from approved sender?
    unless ( $self->approved_sender($msghref) ) {
        $log->error("Unapproved Sender is sending message to SCOT");
        $log->error({ filter => \&Dumper, value => $msghref });
        $self->output("unapproved sender ". $msghref->{from} . " rejected\n");
        return;
    }
    $self->output("---- sender is approved\n");

    # is message a health check?
    if ( $self->is_health_check($msghref) ) {
        $log->trace("Health check received...");
        print "health check...skipping.\n" if ($self->interactive eq "yes" or
                                               $self->verbose == 1);
        $imap->delete_message($msghref->{imap_uid});
        return;
    }

    if ( $self->already_processed($message_id) ) {
        $log->warn("Message_id: $message_id already processed");
        $self->output("--- $message_id already in database\n");
        $imap->see($msghref->{imap_uid});
        return;
    }

    my $parser;

    PCLASS:
    foreach my $pname (keys %{ $self->parsermap } ) {
        next if ( $pname eq "generic" ); # always do this as last resort
        my $pclass = $self->parsermap->{$pname};
        if ( $pclass->will_parse($msghref) ) {
            $parser = $pclass;
            last PCLASS;
        }
    }
    unless ($parser) {
        $parser = $self->parsermap->{generic};
    }

    $self->output("---- parsing with ".ref($parser)."\n");

    my $json_to_post = $parser->parse_message($msghref);
    my $path         = "alertgroup";

    $json_to_post->{message_id}     = $msghref->{message_id};

    unless ( $json_to_post->{subject} ) {
        $json_to_post->{subject}    = $msghref->{subject};
    }
    $json_to_post->{sources}    = [ $parser->get_sourcename ];

    $log->debug("Json to Post = ", {filter=>\&Dumper, value=>$json_to_post});
    $log->debug("posting to $path");

    my $json_returned = $scot->post( $path, $json_to_post );

    unless (defined $json_returned) {
        $log->error("ERROR! Undefined transaction object $path ",
                    {filter=>\&Dumper, value=>$json_to_post});
        $self->output("Post to SCOT failed\n");
        return;
    }
    
    if ( $json_returned->{status} ne "ok" ) {
        $log->error("Failed posting new alertgroup mgs_uid:", $msghref->{imap_uid});
        $log->debug("tx->res is ",{filter=>\&Dumper, value=>$json_returned});
        $self->imap->mark_uid_unseen($msghref->{imap_uid});
        $self->output("Post to SCOT failed.\n");
        return;
    }
    $self->output("---- posted to SCOT.\n");
    $log->trace("Created alertgroup ". $json_returned->{id});
    $imap->see($msghref->{imap_uid});
    return 1;
}

sub output {
    my $self    = shift;
    my $msg     = shift;
    if ( $self->interactive eq "yes" or $self->verbose == 1 ) {
        print $msg;
    }
}

sub already_processed {
    my $self        = shift;
    my $message_id  = shift;
    my $scot        = $self->scot;
    my $return      = $scot->get_alertgroup_by_msgid($message_id);
    my $log         = $self->log;

    $log->debug("Got ag processed ", {filter=>\&Dumper,value=>$return});

    if ($return->{queryRecordCount} > 0) {
        return 1;
    }
    return undef;
}

sub approved_sender {
    my $self    = shift;
    my $href    = shift;
    my $domains = $self->approved_alert_domains;
    my $senders = $self->approved_accounts;
    my $this_sender = $href->{from};
    my $log     = $self->log;

    $this_sender =~ s/<(.*)>/$1/;
    $log->trace("Checking if Sender $this_sender is approved");


    foreach my $as (@$senders) {
        $log->trace("comparing $as");
        if ( $as eq $this_sender ) {
            $log->trace("you are approved!");
            return 1;
        }
    }
    my $this_domain = (split(/\@/, $this_sender))[1];
    $log->trace("not explicitly named, checking domain $this_domain");

    foreach my $ad ( @$domains ) {
        $log->trace("comparing to domain $ad");
        if ( $ad eq $this_domain ) {
            $log->trace("approved domain");
            return 1;
        }
    }
    return undef;
}

sub is_health_check {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->log;

    $log->trace("Checking if this is a health check message");

    my $subject = $href->{subject};

    if ( $subject =~ /SCOT-ALERTS Health Check/i ) {
        $log->trace("It is!");
        # ok, last version had this, but I think it was a kludge
        # keeping this to ignore them when they come in.
        # but a better check might be to see if we haven't received
        # any alerts in x number of minutes
        return 1;
    }
    return undef;
}

1;
