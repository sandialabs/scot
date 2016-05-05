package Scot::Util::Imap;

use lib '../../../lib';

use strict;
use warnings;
use v5.18;

use Readonly;
Readonly my $MSG_ID_FMT => qr/\A\d+\z/;

use Data::Dumper;
use Courriel;
use Try::Tiny::Retry qw/:all/;
use Mail::IMAPClient;
use Scot::Util::Imap::Cursor;

use Moose;

has env     => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
    default     => sub { Scot::Env->instance },
);

has mailbox => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'INBOX',
);

has hostname    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'localhost',
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
    default     => 'scot-alerts',
);

has password    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'needpwhere',
);

has ssl         => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    # default     => sub {[ 'SSL_verify_mode', 'SSL_VERIFY_NONE' ]},
    # default     => sub {[ 'SSL_verify_mode', SSL_VERIFY_NONE ]},
    default     => sub {[ 'SSL_verify_mode', 0 ]},
);

has uid         => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 1,
);

has ignore_size_errors   => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 1,
);

has minutes_ago => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 60,
);

has client => (
    is          => 'ro',
    isa         => 'Mail::IMAPClient',
    required    => 1,
    lazy        => 1,
    builder     => '_connect_to_imap',
    clearer     => 'clear_client_connection',
);

has _client_pid => (
    is          => 'rw',
    isa         => 'Num',
    default     => sub { $$ },
);

sub _connect_to_imap {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

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
    $log->debug("client ",{filter=>\&Dumper, value=> $client});
    return $client;
}

sub check_imap_connection {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    if ( $$ != $self->_client_pid ) {
        $log->trace("Fork detected.  attempting reconnect.");
        $self->_client_pid($$);
        $self->clear_client_connection;
    }
    return;
}

sub get_mail_since {
    my $self    = shift;
    my $epoch   = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    $self->check_imap_connection;
    my $client  = $self->client;
    my $since_epoch = $epoch;

    unless ($since_epoch) {
        my $age = $self->minutes_ago;
        $log->trace("Getting mail from the past $age minutes");
        my $seconds_ago = $age * 60;
        $since_epoch = time() - $seconds_ago;
    }

    $client->select($self->mailbox);
    $client->Peek(1);   # do not mark messages as read

    my @uids;
    $self->env->log->debug("Lookin for messages since $since_epoch");

    foreach my $message_id ($client->since($since_epoch)) {
        if ( $message_id =~ $MSG_ID_FMT ) {
            push @uids, $message_id;
        }
    }
    return wantarray ? @uids : \@uids;
}

sub get_unseen_mail {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    $self->check_imap_connection;
    my $client  = $self->client;

    $log->trace("Retrieving unseen mail");

    $client->select($self->mailbox);
    
    my @unseen_uids = $client->unseen; 

    $log->debug("Unseen Mail: ",{filter=>\&Dumper, value=>\@unseen_uids});

    if ( scalar(@unseen_uids) == 0 ) {
        $log->warn("No unseen messages...");
    }
    else {
        $log->trace(scalar(@unseen_uids)." unread messages found.");
    }
    return wantarray ? @unseen_uids : \@unseen_uids;
}

sub get_unseen_cursor {
    my $self    = shift;
    my @uids    = $self->get_unseen_mail;
    my $cursor  = Scot::Util::Imap::Cursor->new({uids => \@uids});
    return $cursor;
}

sub get_since_cursor {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my ($unit,$amount)  = each %$href;
    my $seconds_ago;

    $env->log->debug("unit $unit amount $amount");

    if ( $unit eq "day" ) {
        $seconds_ago = $amount * 24 * 60 * 60;
    }
    elsif ( $unit eq "hour" ) {
        $seconds_ago = $amount * 60 * 60;
    }
    elsif ( $unit eq "minute" ) {
        $seconds_ago = $amount * 60;
    }
    elsif ( $unit eq "second" ) {
        $seconds_ago = $amount;
    }
    $env->log->debug("seconds ago is $seconds_ago");

    my $since_epoch = $env->now - $seconds_ago;

    $env->log->debug("Lookin for messages since $since_epoch");

    my @uids    = $self->get_mail_since($since_epoch);
    my $cursor  = Scot::Util::Imap::Cursor->new({uids => \@uids});
    return $cursor;
}

sub mark_uid_unseen {
    my $self    = shift;
    my $uid     = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    $self->check_imap_connection;
    my $client  = $self->client;
    my @usuid   = ( $uid );

    $log->trace("marking message $uid as unseen");


    if ( $client->unset_flag('\Seen', @usuid) ) {
        $log->trace("UID $uid is now unseen");
    }
    else {
        $log->error("Failed to mark $uid as unseen");
    }
}

sub get_message {
    my $self    = shift;
    my $uid     = shift;
    my $peek    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    $self->check_imap_connection;
    my $client  = $self->client;

    $log->trace("Getting Message uid=$uid");

    my $envelope;
    try {
        $envelope    = $client->get_envelope($uid);
        $log->trace("Envelope is ",{filter=>\&Dumper,value=>$envelope});
    }
    catch {
        $log->error("Error from IMAP: $_");
    };

    $log->trace("Envelope is ",{filter=>\&Dumper,value=>$envelope});
    $self->client->Peek($peek);

    my %message = (
        imap_uid    => $uid,
        envelope    => $envelope,
        subject     => $self->get_subject($uid),
        from        => $self->get_from($envelope),
        to          => $self->get_to($envelope),
        when        => $self->get_when($uid),
        message_id  => $self->get_message_id($uid),
    );

    ($message{body_html}, 
     $message{body_plain}) = $self->extract_body($uid,$peek);

    return wantarray ? %message : \%message;
}

sub extract_body {
    my $self    = shift;
    my $uid     = shift;

    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Extracting body from uid = $uid");


    my $msgstring   = $self->client->message_string($uid);
    my $email       = Courriel->parse( text => $msgstring );
    my $htmlpart    = $email->html_body_part();
    my $plainpart   = $email->plain_body_part();

    my ($html, $plain);

    if ( $htmlpart ) {
        $html   = $htmlpart->content();
    }
    if ( $plainpart ) {
        $plain  = $plainpart->content();
    }
    return $html, $plain;
}

sub get_subject {
    my $self    = shift;
    my $uid     = shift;
    my $env     = $self->env;
    $self->check_imap_connection;
    my $client  = $self->client;
    my $log     = $env->log;

    my $subject = $client->subject($uid);

    return $subject;
}

sub get_from {
    my $self    = shift;
    my $envelope= shift;
    my $env     = $self->env;
    # my $client  = $self->client;
    my $log     = $env->log;

    return $envelope->from_addresses;
}

sub get_to {
    my $self    = shift;
    my $envelope= shift;
    my $env     = $self->env;
    my $client  = $self->client;
    my $log     = $env->log;

    return join(', ', $envelope->to_addresses);
}

sub get_when {
    my $self    = shift;
    my $uid     = shift;
    my $env     = $self->env;
    $self->check_imap_connection;
    my $client  = $self->client;
    my $log     = $env->log;

    my $courriel    = Courriel->parse( text => $client->message_string($uid) );
    my $dt          = $courriel->datetime();
    my $epoch       = $dt->epoch;

    return $epoch;
}

sub get_message_id {
    my $self    = shift;
    my $uid     = shift;
    my $env     = $self->env;
    $self->check_imap_connection;
    my $client  = $self->client;
    my $log     = $env->log;

    my $msg_id  = $client->get_header($uid, "Message-Id");

    return $msg_id;
}

1;
