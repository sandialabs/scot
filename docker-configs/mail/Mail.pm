package Scot::App::Mail;

use lib '../../../lib';
use lib '/opt/scot/lib';
use Data::Dumper;
use DateTime;
use Try::Tiny;
use Mojo::UserAgent;
use Scot::Env;
use Scot::Util::Imap;
use Scot::Util::ScotClient;
use HTML::TreeBuilder;
use Parallel::ForkManager;
use strict;
use warnings;
use Module::Runtime qw(require_module compose_module_name);
use Log::Log4perl::Level;

use Moose;
extends 'Scot::App';

has get_method  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'mongo',
);

has imap    => (
    is          => 'ro',
    isa         => 'Scot::Util::Imap',
    required    => 1,
    lazy        => 1,
    builder     => '_build_imap',
);

sub _build_imap {
    my $self    = shift;
    my $env     = $self->env;
    return $env->imap;
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

has scot => (
    is          => 'ro',
    isa         => 'Scot::Util::ScotClient',
    required    => 1,
    lazy        => 1,
    builder     => '_build_scot_scot',
);

sub _build_scot_scot {
    my $self    = shift;
    my $env     = $self->env;
    return $env->scot;
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


sub docker {
    my $self    = shift;
    my $log     = $self->log;
    my $env     = $self->env;
    my $interval    = (24 * 60 * 60);
    while (1) {
        $self->run();
        sleep $interval;
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

        my $status = $self->process_message($msg_href);

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
            $log->error("POST to SCOT failed: ", 
            { filter=>\&Dumper, value=>$msg_href});    
        }

        $proc_count++;
        $log->trace("[UID $uid] Child process $pid finishes");

        if ( $self->env->leave_unseen ) {
            print "---- marked as unseen\n" if ($self->verbose);
            $imap->mark_uid_unseen($uid);
        }

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

sub reprocess_alertgroup {
    my $self    = shift;
    my $agid    = shift; # ... alertgroup id
    my $log     = $self->log;
    my $scot    = $self->scot;

    $log->debug("Fetching alertgroup $agid");
    # ... returns href not obj
    my $alertgroup  = $self->get_alertgroup_by_id($agid); 

    unless (defined $alertgroup) {
        $log->error("Alertgroup not found!");
        return;
    }

    $log->debug("Alertgroup dump: ", {filter=>\&Dumper, value=>$alertgroup});

    my $msghref    = {
        subject     => $alertgroup->{subject},
        message_id  => $alertgroup->{message_id},
        body_plain  => $alertgroup->{body_plain},
        body        => $alertgroup->{body},
        source      => $alertgroup->{source},
        when        => $alertgroup->{when},
        data        => [],  # ... emptying it for reparse results
    };

    my $parser                  = $self->get_parser($msghref);
    $log->debug("Message will be parsed by ".ref($parser));
    my $received                = DateTime->from_epoch(epoch=>$msghref->{when});
    my $json_to_post            = $parser->parse_message($msghref);
    my $path                    = "alertgroup";
    $json_to_post->{message_id} = $msghref->{message_id};

    unless ( $json_to_post->{subject} ) {
        $json_to_post->{subject}    = $msghref->{subject};
    }
    $json_to_post->{sources}    = [ $parser->get_sourcename ];
    $json_to_post->{created}    = $received->epoch;

    $log->debug("Json to Post = ", {filter=>\&Dumper, value=>$json_to_post});
    $log->debug("posting to $path");

    my $json_returned_aref = $self->post_alertgroup($json_to_post);
    # use this when update is implemented
    # my $json_returned = $self->put_alertgroup($agid, $json_to_post);

    unless (defined $json_returned_aref) {
        $log->error("ERROR! Undefined transaction object $path ",
                    {filter=>\&Dumper, value=>$json_to_post});
        $self->output("Post to SCOT failed\n");
        return;
    }

    foreach my $json_returned (@$json_returned_aref) {
        if ( $json_returned->{status} ne "ok" ) {
            $log->error("Failed posting new alertgroup mgs_uid:", $msghref->{imap_uid});
            $log->debug("tx->res is ",{filter=>\&Dumper, value=>$json_returned});
            $self->imap->mark_uid_unseen($msghref->{imap_uid});
            $self->output("Post to SCOT failed.\n");
        }
        else {
            $self->output("---- posted to SCOT.\n");
            $log->trace("Created alertgroup ". $json_returned->{id});
        }
    }
    return 1;
}

sub get_parser {
    my $self    = shift;
    my $msg     = shift;
    my $log     = $self->log;
    my $parser;

    PCLASS:
    foreach my $pname (keys %{ $self->parsermap } ) {
        next if ( $pname eq "generic" ); # always do this as last resort
        my $pclass = $self->parsermap->{$pname};
        if ( $pclass->will_parse($msg) ) {
            $log->debug("$pname will parse message");
            $parser = $pclass;
            last PCLASS;
        }
    }
    unless ($parser) {
        $parser = $self->parsermap->{generic};
    }
    return $parser;
}

sub process_message {
    my $self    = shift;
    my $msghref = shift;
    my $log     = $self->log;
    my $scot    = $self->scot;
    my $imap    = $self->imap;
    my $nowdt   = DateTime->now;

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
        return "unapproved";
    }
    $self->output("---- sender is approved\n");

    # is message a health check?
    if ( $self->is_health_check($msghref) ) {
        $log->trace("Health check received...");
        print "health check...skipping.\n" if ($self->interactive eq "yes" or
                                               $self->verbose == 1);
        $imap->delete_message($msghref->{imap_uid});
        $self->put_health_stat({
            amount  => 1,
        });
        return "healthcheck";
    }

    if ( $self->already_processed($message_id) ) {
        $log->warn("Message_id: $message_id already processed");
        $self->output("--- $message_id already in database\n");
        $imap->see($msghref->{imap_uid});
        return "alreadyprocessed";
    }

    my $parser = $self->get_parser($msghref);
    $self->output("---- parsing with ".ref($parser)."\n");

    my $json_to_post = $parser->parse_message($msghref);
    my $path         = "alertgroup";

    $json_to_post->{message_id}     = $msghref->{message_id};

    unless ( $json_to_post->{subject} ) {
        $json_to_post->{subject}    = $msghref->{subject};
    }
    $json_to_post->{sources}    = [ $parser->get_sourcename ];
    $json_to_post->{created}    = $received->epoch;

    $log->debug("Json to Post = ", {filter=>\&Dumper, value=>$json_to_post});
    $log->debug("posting to $path");

    # my $json_returned = $self->post_alertgroup($json_to_post);
    my @returned = $self->post_alertgroup($json_to_post);

    unless (scalar(@returned) > 0 ) {
        $log->error("ERROR! Undefined transaction object $path ",
                    {filter=>\&Dumper, value=>$json_to_post});
        $self->output("Post to SCOT failed\n");
        return "postfailed";
    }

    foreach my $json_returned (@returned) {
    
        if ( $json_returned->{status} ne "ok" ) {
            $log->error("Failed posting new alertgroup mgs_uid:", $msghref->{imap_uid});
            $log->debug("tx->res is ",{filter=>\&Dumper, value=>$json_returned});
            $self->imap->mark_uid_unseen($msghref->{imap_uid});
            $self->output("Post to SCOT failed.\n");
        }
        else {
            $self->output("---- posted to SCOT.\n");
            $log->trace("Created alertgroup ". $json_returned->{id});
            $imap->see($msghref->{imap_uid});
        }
    }
    return 1;
}

# TODO: so reprocessing updated existing alertgroup not create a new one
sub put_alertgroup {
    my $self    = shift;
    my $id      = shift;
    my $data    = shift;
    my $log     = $self->log;
    my $response;

    if ( $self->get_method eq "scot_api" ) {
        $response = $self->scot->put({
            type    => "alertgroup",
            id      => $id,
            data    => $data,
        });
    }
    else {
        $log->debug("Posting via direct mongo access");
        my $mongo   = $self->env->mongo;
        my $agcol   = $mongo->collection('Alertgroup');
        my $agobj   = $agcol->find_iid($id);
    }
}

sub post_alertgroup {
    my $self    = shift;
    my $data    = shift;
    my $log     = $self->log;
    my $response;

    my @responses;
    if ( $self->get_method eq "scot_api" ) {
        $log->debug("Posting via scot api webaccess");
        $response = $self->scot->post({
            type    => "alertgroup",
            data    => $data
        });
    }
    else {
        $log->debug("Posting via direct mongo access");
        my $mongo   = $self->env->mongo;
        my $agcol   = $mongo->collection('Alertgroup');
        my @agobjs  = $agcol->api_create({
            request => { json   => $data }
        });

        foreach my $ag (@agobjs) {

            $self->env->mq->send("scot", {
                action  => "created",
                data    => {
                    type    => "alertgroup",
                    id      => $ag->id,
                    who     => "scot-alerts",
                }
            });
            $response = { 
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
    return wantarray ? @responses : \@responses;
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
    my $return      = $self->get_alertgroup_by_msgid($message_id);
    my $log         = $self->log;

    if (defined($return->{queryRecordCount}) and 
        $return->{queryRecordCount} > 0) {
        $log->debug("already processed");
        return 1;
    }
    $log->debug('not processed yet');
    return undef;
}

sub get_alertgroup_by_msgid {
    my $self    = shift;
    my $msgid   = shift;
    my $log     = $self->log;
   
    $log->debug("Looking for AG with msgid of ".$msgid);

    if ( $self->get_method  eq "scot_api" ) {
        return $self->scot->get_alertgroup_by_mesgid($msgid);
    }
    else {
        my $mongo   = $self->env->mongo;
        my $col     = $mongo->collection('Alertgroup');
        my $obj     = $col->find_one({message_id => $msgid});
        if ( $obj ) {
            $log->debug("found match at ag:".$obj->id);
            return { queryRecordCount => 1 };
        }
    }
    $log->debug("no matching alertgroups");
    return { error => 1 };
}

sub get_alertgroup_by_id {
    my $self    = shift;
    my $id      = shift;

    if ( $self->get_method eq "scot_api" ) {
        return $self->scot->get({ 
            id      => $id,
            type    => "alertgroup",
        });
    }
    else {
        my $mongo   = $self->env->mongo;
        my $col     = $mongo->collection('Alertgroup');
        my $obj     = $col->find_iid($id);
        if ( $obj ) {
            return $obj->as_hash;
        }
    }
    return { error => 1};
}


sub approved_sender {
    my $self    = shift;
    my $href    = shift;
    my $domains = $self->approved_alert_domains;
    my $senders = $self->approved_accounts;
    my $this_sender = $href->{from};
    my $log     = $self->log;

    $this_sender =~ s/<(.*)>/$1/;
    $log->debug("Checking if Sender $this_sender is approved");


    foreach my $as (@$senders) {
        $log->debug("comparing $as");
        if ( $as eq $this_sender ) {
            $log->debug("you are approved!");
            return 1;
        }
    }
    my $this_domain = (split(/\@/, $this_sender))[1];
    $log->debug("not explicitly named, checking domain $this_domain");

    foreach my $ad ( @$domains ) {
        $log->debug("comparing to domain $ad");
        # if ( $ad eq $this_domain ) {
        if ( $ad =~ /$this_domain$/ ) {
            $log->debug("approved domain");
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

    if ( $subject =~ /SCOT Health Check/i ) {
        $log->trace("It is!");
        $log->debug("Health check subject is: $subject");
        # ok, last version had this, but I think it was a kludge
        # keeping this to ignore them when they come in.
        # but a better check might be to see if we haven't received
        # any alerts in x number of minutes
        return 1;
    }
    return undef;
}

sub put_health_stat {
    my $self    = shift;
    my $href    = shift;
    my $now     = DateTime->now;

    if ( $self->get_method eq "scot_api" ) {
        my $response = $self->scot->post({
            type    => "stat",
            data    => {
                action  => 'incr',
                year    => $now->year,
                month   => $now->month,
                day     => $now->day,
                hour    => $now->hour,
                dow     => $now->dow,
                quarter => $now->quarter,
                metric  => 'mail healthcheck received',
                value   => $href->{amount},
            }
        });
    }
    else {
        my $mongo   = $self->env->mongo;
        my $col     = $mongo->collection('Stat');
        $col->increment($now, "mail healthcheck received", $href->{amount});
    }
}

1;
