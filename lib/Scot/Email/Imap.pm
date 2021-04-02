package Scot::Email::Imap;

use lib '../../../lib';
use strict;
use warnings;

use Readonly;
Readonly my $MSG_ID_FMT => qr/\A\d+\z/;

use Data::Dumper;
use Courriel;
use MIME::Parser;
use Try::Tiny::Retry qw/:all/;
use Mail::IMAPClient;
use Scot::Email::Imap::Cursor;
use HTML::Element;
use URI;

use Moose;

has env => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required=> 1,
);

has test => (
    is      => 'ro',
    isa     => 'Bool',
    required    => 1,
    default => 0,
);

has mailbox => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has hostname    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has port        => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 993,
);

has username    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has password     => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has ssl         => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub {[]},
);

has uid     => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 1,
);

has ignore_size_errors => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 1
);

has test_mode   => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

has client  => (
    is          => 'ro',
    isa         => 'Mail::IMAPClient',
    required    => 1,
    lazy        => 1,
    builder     => '_build_imap',
    clearer     => '_clear_imap',
);

has client_pid  => (
    is          => 'ro',
    isa         => 'Num',
    default     => sub { $$ },
);

has permitted_senders => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub {['*']},
);

has peeking => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
);

sub _build_imap {
    my $self    = shift;
    my $log     = $self->env->log;

    my @options = (
        Server              => $self->hostname,
        Port                => $self->port,
        User                => $self->username,
        Password            => $self->password,
        Ssl                 => $self->ssl,
        Uid                 => $self->uid,
        Ignoresizeerrors    => $self->ignore_size_errors,
    );

    $log->trace("Initializing IMAP client w/ options: ", 
                {filter =>\&Dumper, value => \@options});
    
    my $client = retry {
        Mail::IMAPClient->new(@options);
    }
    delay_exp {
        5, 1e6
    }
    catch {
        $log->error("Failed to connect to IMAP server!");
        $log->error($_);
        # undef $client;
    };
    $log->debug("Imap connected...");
    $log->trace("client ",{filter=>\&Dumper, value=> $client});

    if ( $self->test_mode ) {
        $log->debug("In test mode, setting Peek to 1");
        $client->Peek(1);
    }
    if ( $self->peeking ) {
        $client->Peek(1);
    }
    return $client;
}

has seconds_ago => (
    is      => 'ro',
    isa     => 'Int',
    required    => 1,
    default => sub { 60 * 60 * 24 * 1 },
);

sub since {
    my $self    = shift;
    my $seconds_ago = $self->seconds_ago;
    my $since = time() - $seconds_ago;
    return $since;
}

sub reconnect_if_forked {
    my $self    = shift;
    my $log     = $self->env->log;

    if ( $$ != $self->client_pid ) {
        $log->trace("Fork detected.  attempting reconnect.");
        $self->_client_pid($$);
        $self->_clear_imap; # force rebuild of self->client
    }
    return;
}

sub get_mail {
    my $self    = shift;
    my $test    = $self->test;
    my $log     = $self->env->log;

    $log->debug("get_mail: mode = $test");

    if ( $test == 1 ) {
        return $self->get_since_cursor();
    }

    return $self->get_unseen_cursor();
}


sub get_unseen_cursor {
    my $self    = shift;
    my @uids    = ();

    @uids = $self->get_unseen_mail;

    my $cursor  = Scot::Email::Imap::Cursor->new({imap => $self, uids => \@uids});
    return $cursor;
}

sub get_unseen_mail {
    my $self    = shift;
    my $log     = $self->env->log;
    $self->reconnect_if_forked;
    my $client  = $self->client;

    $log->trace("Retrieving unseen mail");

    my @unseen_uids;
    retry {
        $client->select($self->mailbox);
        @unseen_uids = $client->unseen; 
        $log->debug("Unseen Mail: ",{filter=>\&Dumper, value=>\@unseen_uids});
    }
    on_retry {
        $self->clear_client_connection;
    }
    catch {
        $log->error("Failed to get unseen messages: $_");
        die "Failed to get unseen messages\n";
    };

    if ( scalar(@unseen_uids) == 0 ) {
        $log->warn("No unseen messages...");
    }
    else {
        $log->trace(scalar(@unseen_uids)." unread messages found.");
    }
    return wantarray ? @unseen_uids : \@unseen_uids;
}

sub get_since_cursor {
    my $self    = shift;
    my $since   = $self->since();
    my @uids    = ();

    $self->env->log->debug("Retrieving mail since ".$self->env->get_human_time($since));

    @uids = $self->get_mail_since($since);

    my $cursor  = Scot::Email::Imap::Cursor->new({imap => $self, uids => \@uids});
    return $cursor;
}

sub get_mail_since {
    my $self    = shift;
    my $since   = shift;
    my $log     = $self->env->log;
    $self->reconnect_if_forked;
    my $client  = $self->client;

    if ( ! defined $since ) {
        $since = $self->since();
    }

    my @uids;
    retry {
        $client->select($self->mailbox);
        foreach my $message_id ($client->since($since)) {
            if ( $message_id =~ $MSG_ID_FMT ) {
                push @uids, $message_id;
            }
        }
    }
    on_retry {
        $self->clear_client_connection;
    }
    catch {
        $log->logdie("Failed to set messages since $since: $_");
    };
    return wantarray ? @uids :\@uids;
}

sub get_envelope_from_uid {
    my $self    = shift;
    my $uid     = shift;
    my $log     = $self->env->log;
    my $envelope;

    retry {
        $envelope    = $self->client->get_envelope($uid);
        $log->trace("Envelope is ",{filter=>\&Dumper,value=>$envelope});
    }
    on_retry {
        $self->clear_client_connection;
    }
    catch {
        $log->error("Error from IMAP: $_");
    };

    $log->trace("Envelope is ",{filter=>\&Dumper,value=>$envelope});

    return $envelope;
}


sub get_message {
    my $self    = shift;
    my $uid     = shift;
    my $peek    = shift;
    my $log     = $self->env->log;
    $self->reconnect_if_forked;
    my $client  = $self->client;

    return unless $uid;

    my $mode = $peek ? "Peeking" : "Nonpeeking";
    $log->trace("Getting Message uid=$uid ($mode)");
    $self->client->Peek($peek);

    my $envelope = $self->get_envelope_from_uid($uid);
    my $from     = $self->get_from($envelope);

    if ( ! $self->from_permitted_sender($from))  {
        $log->warn("Message from $from that is not in the permitted senders list");
        return undef;
    }

    my %message = (
        imap_uid    => $uid,
        # envelope    => $envelope, # this is an obj and doesn't go on queue
        subject     => $self->get_subject($uid),
        from        => $from,
        to          => $self->get_to($envelope),
        when        => $self->get_when($uid),
        message_id  => $self->get_message_id($uid),
        message_str => $self->client->message_string($uid),
    );

    return wantarray ? %message : \%message;
}

sub from_permitted_sender {
    my $self    = shift;
    my $from    = shift;
    my @oksenders   = @{$self->permitted_senders};
    my $log     = $self->env->log;

    # each permitted sender can be a regex, 
    # a '*' match all wildcard, or and explicit
    # string match

    foreach my $oksender (@oksenders) {

        if ( $self->regex_match($oksender, $from) 
             or $self->wildcard_match($oksender)
             or $self->explicit_match($oksender, $from)
           ) {
                return 1;
        }
    }
}

sub regex_match {
    my $self    = shift;
    my $ok      = shift;
    my $from    = shift;

    if ( ref($ok) ) {
        return $from =~ /$ok/;
    }
    return undef;
}

sub wildcard_match {
    my $self    = shift;
    my $ok      = shift;
    return $ok eq '*';
}

sub explicit_match {
    my $self    = shift;
    my $ok      = shift;
    my $from    = shift;
    return $ok eq $from;
}


sub get_subject {
    my $self    = shift;
    my $uid     = shift;
    $self->reconnect_if_forked;
    my $client  = $self->client;
    my $log     = $self->env->log;

    my $subject = retry {
        $client->subject($uid);
    }
    on_retry{
        $self->clear_client_connection;
    }
    delay_exp {
        5, 1e6
    }
    catch {
        $log->error("Failed to get subject");
        $log->error($_);
    };


    return $subject;
}

sub get_from {
    my $self    = shift;
    my $envelope= shift;
    # my $client  = $self->client;
    my $log     = $self->env->log;

    my $angle_quoted = $envelope->from_addresses;

    (my $from = $angle_quoted) =~ s/[<>]//g; # strip <> 
    return $from;
}

sub get_to {
    my $self    = shift;
    my $envelope= shift;
    my $log     = $self->env->log;

    return join(', ', $envelope->to_addresses);
}

sub get_when {
    my $self    = shift;
    my $uid     = shift;
    $self->reconnect_if_forked;
    my $client  = $self->client;
    my $log     = $self->env->log;
    my $msgstring   = retry {
        $client->message_string($uid);
    }
    on_retry {
        $self->clear_client_connection;
    }
    delay_exp {
        5, 1e6
    }
    catch {
        $log->error("failed to get message string");
    };

    my $courriel    = Courriel->parse( text => $msgstring );
    my $dt          = $courriel->datetime();
    my $epoch       = $dt->epoch;

    return $epoch;
}

sub get_message_id {
    my $self    = shift;
    my $uid     = shift;
    $self->reconnect_if_forked;
    my $client  = $self->client;
    my $log     = $self->env->log;

    my $msg_id  = retry {
        $client->get_header($uid, "Message-Id");
    }
    on_retry {
        $self->clear_client_connection;
    }
    delay_exp {
        5, 1e6
    }
    catch {
        $log->error("failed to get Message-Id header");
    };

    return $msg_id;
}

1;

