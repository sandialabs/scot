package Scot::Email::Imap;

use lib '../../../lib';
use strict;
use warnings;

use Readonly;
Readonly my $MSG_ID_FMT => qr/\A\d+\z/;

use Data::Dumper;
use Data::GUID;
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
    $log->trace("client ",{filter=>\&Dumper, value=> $client});

    if ( $self->test_mode ) {
        $log->debug("In test mode, setting Peek to 1");
        $client->Peek(1);
    }
    return $client;
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

sub get_unseen_cursor {
    my $self    = shift;
    my @uids    = ();

    if ( $self->test_mode ) {
        @uids = $self->get_mail_since();
    }
    else {
        @uids = $self->get_unseen_mail;
    }

    my $cursor  = Scot::Email::Imap::Cursor->new({uids => \@uids});
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

sub get_mail_since {
    my $self    = shift;
    my $epoch   = shift;
    my $log     = $self->env->log;
    $self->reconnect_if_forked;
    my $client  = $self->client;
    my $since   = $epoch;

    if ( ! defined $since ) {
        my $seconds_ago = 60 * 60 * 24 * 7; # past week
        $since = time() - $seconds_ago;
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

sub get_message {
    my $self    = shift;
    my $uid     = shift;
    my $peek    = shift;
    my $log     = $self->env->log;
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

    my $from    = $self->get_from($envelope);

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
    );

    ($message{body_html}, 
     $message{body_plain},
     $message{images},
     $message{attachments},
     $message{received}) = $self->extract_body($uid,$peek);

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

sub extract_body {
    my $self    = shift;
    my $uid     = shift;

    my $log     = $self->env->log;

    $log->trace("Extracting body from uid = $uid");


    my $msgstring   = $self->client->message_string($uid);
    my $email       = Courriel->parse( text => $msgstring );
    my $htmlpart    = $email->html_body_part();
    my $plainpart   = $email->plain_body_part();
    my $attached    = $self->get_attached_files($email);
    my $received    = $email->datetime->epoch;

    # $log->logdie({filter=>\&Dumper, value=>$attached}) if (%{$attached});

    my ($html, $plain);

    if ( $htmlpart ) {
        $html   = $htmlpart->content();
    }
    if ( $plainpart ) {
        $plain  = $plainpart->content();
    }
    my $images = $attached->{images};
    my $files  = $attached->{files};
    return $html, $plain, $images, $files, $received;
}

sub mime_tools {
    my $self        = shift;
    my $msgstring   = shift;

    my $log = $self->env->log;
    $log->debug("Using MIME tools to parse and find attachments");

    my $mparser     = MIME::Parser->new();
    my $entity      = $mparser->parse_data($msgstring);
}

sub dump_mime_entity {
    my $self    = shift;
    my $entity  = shift;
    my $name    = shift;

    defined($name) || $name = 'anonymous';

    my $IO;

    $self->dump_head($entity, $name);
    $self->dump_body($entity, $name);

}

sub dump_head {
    my $self    = shift;
    my $entity  = shift;
    my $name    = shift;

    my $log     = $self->env->log;
    my $msg     =   "\n".
                    '='x60."\n".
                    "Message $name: \n".
                    '='x60."\n".
                    $entity->head->original_text.
                    "\n";
    $log->debug($msg);
}

sub dump_body {
    my $self    = shift;
    my $entity  = shift;
    my $name    = shift;
    my $log     = $self->env->log;

    my @parts   = $entity->parts;
    
    if ( @parts ) {
        my $i   = 0;
        foreach $i (0..scalar(@parts)) {
            $self->dump_entity($parts[$i], ("$name, part ".(1+$i)));
        }
    }
    else {
        my ($type, $subtype) = split('/', $entity->head->mime_type);
        my $body             = $entity->bodyhandle;
        if ($type =~ /^(text|message)$/) {
            if ( $IO = $body->open('r')) {
                my $contents;
                while (defined($_ = $IO->getline)) {
                    $contents .= $_;
                }
                $IO->close;
                $log->debug("$type entity part contents:\n".$contents);
            }
            else {
                $log->error("Could not fine $name: $!");
            }
        }
        else {
            my $path    = $body->path
            my $size    = ($path ? (-s $path) : '???');
            $log->debug("Non-text message $size bytes long, stored at ".($path ? "$path" : "core"));
        }
    }
}

sub get_attached_files {
    my $self        = shift;
    my $email   = shift;
    my $log         = $self->env->log;
    my %files       = ();

    foreach my $part ($email->parts()) {
        if ( $part->is_multipart ) {
            $log->warn("Mulitpart Part detected!");
        }
        my $mime     = $part->mime_type;
        my $filename = try {
            $self->normalize_filename($part->filename);
        }
        catch {
            $log->error("Part->filename failed?");
            $log->error({filter=>\&Dumper, value => $part});
        };
        if ( $mime =~ /image/ ) {
            my $encoding    = $part->encoding;
            my $content     = $part->content;
            $files{images}{$filename} = $self->build_img($mime, $content, $filename);
        }
        if ( $part->is_attachment ) {
            my $content     = $part->content;
            $files{files}{$filename} = { # allow responder to create files
                content => $content,
                mime    => $mime,
            };
        }
    }
    # $log->debug({filter=>\&Dumper, value=> $files{files}}) if (%files);
    return \%files;
}

sub normalize_filename {
    my $self    = shift;
    my $name    = shift;
    my $norm    = '';
    my $log     = $self->env->log;


    if ( defined $name ) {
        $log->debug("normalizing $name");
        # remove spaces
        ($norm = $name) =~ s/[ ,]/_/g;
    }
    else {
        my $guid = Data::GUID->new;
        $norm = $guid->as_string;
    }
    $log->debug("norm name is $norm");
    return $norm;
}

sub build_img {
    my $self    = shift;
    my $mime    = shift;
    my $data    = shift;
    my $name    = shift;
    my $uri     = URI->new("data:");
    $uri->media_type($mime);
    $uri->data($data);
    # return qq(<img src="$uri" alt="$name">);
    my $h       = HTML::Element->new('img','src'=>$uri, 'alt'=>$name);
    return $h;
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

sub extract_images {
    my $self    = shift;
    my $msg     = shift;
    my $log     = $self->env->log;

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

