package Scot::Util::Imap;

use lib '../../../lib';

use strict;
use warnings;

use Readonly;
Readonly my $MSG_ID_FMT => qr/\A\d+\z/;

use Data::Dumper;
use Courriel;
use Try::Tiny::Retry qw/:all/;
use Mail::IMAPClient;
use Scot::Util::Imap::Cursor;

use Moose;

extends 'Scot::Util';

has mailbox => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    # default     => 'INBOX',
    builder     => '_build_mailbox',
);

sub _build_mailbox {
    my $self    = shift;
    my $config  = $self->config;
    my $attr    = 'mailbox';
    my $default = 'INBOX';
    return $self->get_config_value($attr,$default);
}

has hostname    => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    # default     => 'localhost',
    builder     => '_build_hostname',
);

sub _build_hostname {
    my $self    = shift;
    my $config  = $self->config;
    my $attr    = 'hostname';
    my $default = 'localhost';
    return $self->get_config_value($attr,$default);
}

has port        => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    # default     => 993,
    builder     => '_build_port',
);

sub _build_port {
    my $self    = shift;
    my $config  = $self->config;
    my $attr    = 'port';
    my $default = 993;
    return $self->get_config_value($attr,$default);
}

has username    => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    # default     => 'scot-alerts',
    builder     => '_build_username',
);

sub _build_username {
    my $self    = shift;
    my $config  = $self->config;
    my $attr    = 'username';
    my $default = "scot-alerts";
    return $self->get_config_value($attr,$default);
}

has password    => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    # default     => 'needpwhere',
    builder     => '_build_password'
);

sub _build_password {
    my $self    = shift;
    my $config  = $self->config;
    my $attr    = 'password';
    my $default = "changemenow";
    return $self->get_config_value($attr,$default);
}

has ssl         => (
    is          => 'ro',
    isa         => 'ArrayRef',
    lazy        => 1,
    required    => 1,
    # default     => sub {[ 'SSL_verify_mode', 'SSL_VERIFY_NONE' ]},
    # default     => sub {[ 'SSL_verify_mode', SSL_VERIFY_NONE ]},
    # default     => sub {[ 'SSL_verify_mode', 0 ]},
    builder     => '_build_ssl',
);

sub _build_ssl {
    my $self    = shift;
    my $config  = $self->config;
    my $attr    = 'ssl';
    my $default = [ 'SSL_verify_mode', 0 ];
    return $self->get_config_value($attr,$default);
}

has uid         => (
    is          => 'ro',
    isa         => 'Int',
    lazy        => 1,
    required    => 1,
    # default     => 1,
    builder     => '_build_uid',
);

sub _build_uid {
    my $self    = shift;
    my $config  = $self->config;
    my $attr    = 'uid';
    my $default = 1;
    return $self->get_config_value($attr,$default);
}

has ignore_size_errors   => (
    is          => 'ro',
    isa         => 'Int',
    lazy        => 1,
    required    => 1,
    # default     => 1,
    builder     => '_build_ignore_size_errors',
);

sub _build_ignore_size_errors {
    my $self    = shift;
    my $config  = $self->config;
    my $attr    = 'ignore_size_errors';
    my $default = 1;
    return $self->get_config_value($attr,$default);
}

has minutes_ago => (
    is          => 'ro',
    isa         => 'Int',
    lazy        => 1,
    required    => 1,
    default     => 60,
);

sub _build_minutes_ago {
    my $self    = shift;
    my $config  = $self->config;
    my $attr    = 'minutes_ago';
    my $default = 60;
    return $self->get_config_value($attr,$default);
}

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

    $log->debug("Initializing IMAP client w/ options: ", 
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

sub reconnect_if_forked {
    my $self    = shift;
    my $log     = $self->log;

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
    my $log     = $self->log;
    $self->reconnect_if_forked;
    my $client  = $self->client;
    my $since_epoch = $epoch;

    unless ($since_epoch) {
        my $age = $self->minutes_ago;
        $log->trace("Getting mail from the past $age minutes");
        my $seconds_ago = $age * 60;
        $since_epoch = time() - $seconds_ago;
    }

    retry {
        $client->select($self->mailbox);
    }
    on_retry {
        $self->clear_client_connection;
    }
    catch {
        $log->error("Failed to reconnect to IMAP server to perform select");
        $log->error($_);
        die "Failed to reconnect to IMAP server for select operation\n";
    };
    $client->Peek(1);   # do not mark messages as read

    my @uids;
    $self->log->debug("Lookin for messages since $since_epoch");

    foreach my $message_id ($client->since($since_epoch)) {
        if ( $message_id =~ $MSG_ID_FMT ) {
            push @uids, $message_id;
        }
    }
    return wantarray ? @uids : \@uids;
}

sub get_unseen_mail {
    my $self    = shift;
    my $log     = $self->log;
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

sub get_unseen_cursor {
    my $self    = shift;
    my @uids    = $self->get_unseen_mail;
    my $cursor  = Scot::Util::Imap::Cursor->new({uids => \@uids});
    return $cursor;
}

sub see {
    my $self    = shift;
    my $uid     = shift;
    my $log     = $self->log;
    retry {
        $self->client->see($uid);
    }
    on_retry {
        $self->clear_client_connection;
    }
    catch {
        $log->error("Failed to mark message $uid as seen");
    };
}

sub get_since_cursor {
    my $self    = shift;
    my $href    = shift;
    my ($unit,$amount)  = each %$href;
    my $seconds_ago;

    $self->log->debug("unit $unit amount $amount");

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
    $self->log->debug("seconds ago is $seconds_ago");

    my $since_epoch = time() - $seconds_ago;

    $self->log->debug("Lookin for messages since $since_epoch");

    my @uids    = $self->get_mail_since($since_epoch);
    my $cursor  = Scot::Util::Imap::Cursor->new({uids => \@uids});
    return $cursor;
}

sub mark_uid_unseen {
    my $self    = shift;
    my $uid     = shift;
    my $log     = $self->log;
    $self->reconnect_if_forked;
    my $client  = $self->client;
    my @usuid   = ( $uid );

    $log->trace("marking message $uid as unseen");

    retry {
        $client->unset_flag('\Seen', @usuid);
    } 
    on_retry {
        $self->clear_client_connection;
    }
    catch {
        $log->error("Failed to mark $uid as unseen");
    }
}

sub delete_message {
    my $self    = shift;
    my $uid     = shift;
    my $log     = $self->log;
    $self->reconnect_if_forked;
    my $client  = $self->client;
    my $usuid   = [ $uid ];

    retry {
        $client->delete_message($usuid);
    }
    on_retry {
        $self->clear_client_connection;
    }
    catch {
        $log->error("Error deleting $uid");
    };
}


sub get_message {
    my $self    = shift;
    my $uid     = shift;
    my $peek    = shift;
    my $log     = $self->log;
    $self->reconnect_if_forked;
    my $client  = $self->client;

    $log->trace("Getting Message uid=$uid");

    my $envelope;
    retry {
        $envelope    = $client->get_envelope($uid);
        $log->trace("Envelope is ",{filter=>\&Dumper,value=>$envelope});
    }
    on_retry {
        $self->clear_client_connection;
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

    my $log     = $self->log;

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
    $self->reconnect_if_forked;
    my $client  = $self->client;
    my $log     = $self->log;

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
    my $log     = $self->log;

    return $envelope->from_addresses;
}

sub get_to {
    my $self    = shift;
    my $envelope= shift;
    my $log     = $self->log;

    return join(', ', $envelope->to_addresses);
}

sub get_when {
    my $self    = shift;
    my $uid     = shift;
    $self->reconnect_if_forked;
    my $client  = $self->client;
    my $log     = $self->log;
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
    my $log     = $self->log;

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

sub extract_images {
    my $self    = shift;
    my $msg     = shift;
    my $log     = $self->log;

    my @parts   = $msg->parts();
    my @htmls   = ();

    foreach my $part (@parts) {
        my $mt  = $part->mime_type();
        my $enc = $part->encoding();
        $log->debug("part mime: $mt, encoding: $enc");
        next unless ($enc =~ /base64/i);
        if ( $mt =~ /image/ ) {
            my $b64image = $part->encoded_content();
            my $html    = join('',
                '<img src="data::image/jpeg;base64,',
                $b64image,
                '">');
            push @htmls, $html;
        }
    }
    return wantarray ? @htmls : \@htmls;
}

1;
