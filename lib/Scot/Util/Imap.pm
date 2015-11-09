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

has client => (
    is          => 'ro',
    isa         => 'Mail::IMAPClient',
    required    => 1,
    lazy        => 1,
    builder     => '_connect_to_imap',
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
    default     => [ 'SSL_verify_mode', 'SSL_VERIFY_NONE' ],
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


sub _connect_to_imap {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $self->log;

    my @options = (
        Server              => $self->hostname,
        Port                => $self->port,
        User                => $self->username,
        Password            => $self->password,
        Ssl                 => $self->ssl,
        Uid                 => $self->uid,
        Ignoresizeerrors    => $self->ignore_size_errors,
    );

    $log->trace("Initializing IMAP client w/ options: ", {filter =>\&Dumper, value => \@options});
    
    my $client;

    retry {
        $client  = Mail::IMAPClient->new(@options);
    }
    delay_exp {
        5, 1e6
    }
    catch {
        $log->error("Failed to connect to IMAP server!");
        undef $client;
    };
    return $client;
}

sub get_unseen_mail {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $client  = $self->client;

    $log->trace("Retrieving unseen mail");

    unless ($client) {
        $log->error("IMAPClient not initialized...");
        $self->_connect_to_imap;
    }
    
    my @unseen_uids = $client->unseen; 

    if ( scalar(@unseen_uids) == 0 ) {
        $log->warn("No unseen messages...");
    }
    else {
        $log->trace(scalar(@unseen_uids)." unread messages found.");
    }
    return wantarray ? @unseen_uids : \@unseen_uids;
}

sub mark_uid_unseen {
    my $self    = shift;
    my $uid     = shift;
    my $env     = $self->env;
    my $log     = $env->log;
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
    my $env     = $self->env;
    my $log     = $env->log;
    my $client  = $self->client;

    $log->trace("Getting Message uid=$uid");

    my $envelope    = $client->get_envelope($uid);

    my %message = (
        imap_uid    => $uid,
        envelope    => $envelope,
        subject     => $self->get_subject($uid),
        from        => $self->get_from($envelope),
        to          => $self->get_to($envelope),
        when        => $self->get_when($uid),
        message_id  => $self->get_message_id($uid),
    );

    ($message{body_html}, $message{body_plain}) = $self->extract_body($uid);

    return wantarray ? %message : \%message;
}

sub get_subject {
    my $self    = shift;
    my $uid     = shift;
    my $env     = $self->env;
    my $client  = $self->client;
    my $log     = $env->log;

    my $subject = $client->subject($uid);

    return $subject;
}

sub get_from {
    my $self    = shift;
    my $envelope= shift;
    my $env     = $self->env;
    my $client  = $self->client;
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
    my $client  = $self->client;
    my $log     = $env->log;

    my $msg_id  = $client->get_header($uid, "Message-Id");

    return $msg_id;
}

1;
