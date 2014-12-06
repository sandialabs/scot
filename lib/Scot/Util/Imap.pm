package Scot::Util::Imap;

use lib '../../../lib';
use lib '../../lib';
use lib '../lib';
use strict;
use warnings;
use v5.10;

use Readonly;
Readonly my $MESSAGE_ID_FMT => qr/\A\d+\z/;

use Data::Dumper;
use Scot::Util::Mongo;
use Net::LDAP;
use Courriel;
use Moose;
use namespace::autoclean;


has config      => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

has 'log'       => (
    is          => 'ro',
    isa         => 'Object',
    required    => 1,
);

has 'env'       => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
);

has minutes_ago => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 60,
);

has mailbox => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'INBOX',
);

has 'imap_client'   => (
    is          => 'rw',
    isa         => 'Mail::IMAPClient',
    required    => 1,
    lazy        => 1,
    builder     => 'connect_to_imap',
);

has 'mongo' => (
    is          => 'ro',
    isa         => 'Scot::Util::Mongo',
    required    => 1,
);

sub connect_to_imap {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->log;
    my @options = $self->build_options($href);

    $log->debug("++++ Building IMAP connection ");
    $log->debug("++++ OPTS  : ".Dumper(@options));

    my $imap_alerts = Mail::IMAPClient->new(@options);
    $log->debug("++++ IMAP connection made");
    unless ($imap_alerts) {
        $log->error("Problem with imap connection!");
    }
    return $imap_alerts;
}

sub build_options {
    my $self    = shift;
    my $href    = shift;
    my $config  = $self->config;
    my $ihref   = $config->{imap};
    my $user    = $config->{imap}->{username};
    my $pw      = $config->{email_accounts}->{$user};
    my $ise     = $config->{imap}->{ignoresizeerrors};

    my @options = (
        Server              => $href->{hostname} // $ihref->{hostname},
        Port                => $href->{port}     // $ihref->{port},
        User                => $href->{user}     // $user,
        Password            => $href->{passwd}   // $pw,
        Ssl                 => $href->{ssl}      // $ihref->{ssl},
        Uid                 => $href->{uid}      // $ihref->{uid},
        Ignoresizeerrors    => $href->{ignoresizeerrors} // $ise,
        SSL_verify_mode     => "SSL_VERIFY_NONE",
    );
    return @options;
}


sub get_messages_aref {
    my $self        = shift;
    my $opts_href   = shift;
    my $log         = $self->log;
    my $imap        = $self->imap_client;

    $log->debug("building message aref...");
    $log->debug("Retrieving messages with opts: ".Dumper($opts_href));
    $log->debug("imap is ".ref($imap));
    $log->debug("isConnected: ".$imap->IsConnected);
    $log->debug("isAuthenitcated: ".$imap->IsAuthenticated);

    if ( $opts_href->{mail_box} ) {
        $self->mailbox($opts_href->{mail_box});
    }
    my $box     = $self->mailbox;

    unless ( $imap->select($box) ) {
        $log->error("Failed to select $box!");
        return undef;
    }

    unless ( $opts_href->{mark_as_read} ) {
        $log->debug("Leaving Mail messages marked UNread");
        $imap->Peek(1);
    }

    if ( $opts_href->{minutes_ago} and $opts_href->{minutes_ago} > 0  ) {
        $self->minutes_ago($opts_href->{minutes_ago});
    }

    my $seconds_ago     = time() - (60 * $self->minutes_ago);

    $log->debug("Retrieving messages received since $seconds_ago seconds");

    my @messages;
    foreach my $message_id ( $imap->since($seconds_ago) ) {
        if ( $message_id =~ $MESSAGE_ID_FMT ) {
            push @messages, $message_id;
        }
    }
    return \@messages;
}

sub get_message {
    my $self        = shift;
    my $id          = shift;
    my $hid         = shift;
    my $msg_href    = $self->build_message_href($id);

    my %data    = (
        message_id          => $id,
        header_message_id   => $hid,
        parser              => $self->select_parser($msg_href),
        msg_href            => $msg_href,
    );
    return \%data;
}

sub get_header_msg_id {
    my $self    = shift;
    my $id      = shift;
    my $imap    = $self->imap_client;
    my $log     = $self->log;
    my $msgid   = $imap->get_header($id, "Message-Id");
    $log->debug("retrieved message-id of ".Dumper($msgid));
    return $msgid;
}

sub build_message_href  {
    my $self    = shift;
    my $id      = shift;
    my $imap    = $self->imap_client;
    my $log     = $self->log;

    my $msg_id      = $imap->get_header($id, "Message-Id");
    my $envelope    = $imap->get_envelope($id);
    my $when        = $self->get_when($id);
    my $bodyhref    = $self->extract_body($id);

    my $href    = {
        imap_id     => $id,
        envelope    => $envelope,
        subject     => $self->get_subject($id),
        from        => $self->get_from($envelope),
        to          => join(', ', $envelope->to_addresses),
        when        => $when,
        sources     => $self->get_source($envelope, $id),
        created     => $when,
        message_id  => $msg_id,
        body_html   => $bodyhref->{html},
        body_plain  => $bodyhref->{plain},
    };
    $log->debug("Message href is ".Dumper($href));
    return $href;
}

sub get_from {
    my $self        = shift;
    my $envelope    = shift;
    my $log         = $self->log;
    my $address     = $envelope->from_addresses;
    return $address;
}

sub get_when {
    my $self    = shift;
    my $id      = shift;
    my $imap    = $self->imap_client;
    my $log     = $self->log;

    $log->debug("Getting Message timestamp");

    my $message_string  = $imap->message_string($id);
    my $courriel        = Courriel->parse( text => $message_string );
    my $dt              = $courriel->datetime();
    my $epoch           = $dt->epoch;

    $log->debug("GET_WHEN");
    $log->debug("Message received @ : ".$dt->ymd." ".$dt->hms);
    $log->debug("Message received @ epoch: ".$epoch);
    $log->debug("NOW is                    ".time());
    return $epoch;
}

sub get_source {
    my $self        = shift;
    my $envelope    = shift;
    my $id          = shift;
    my $log         = $self->log;
    my $from        = $envelope->from_addresses;
    $from           =~ m/[<]+(.*)@/;
    my $source      = $1;

    $log->debug("getting source");
    $log->debug("$source obtained from $from");

    if ($source eq '') {
        $from       = m/(.*)@/;
        $source     = $1;
    }

    if ( $source eq "do-not-reply" ) {
        my $from    = $self->get_from($envelope);
        if ( $from =~ /fireeye/i ) {
            $source = "FireEye";
        }
    }

    if ( $source eq "NIL" ) {
        # See if Courriel can find it
        my $subject = $self->get_subject($id);
        if ( $subject eq "Ascan Daily Report") {
            $source = "ascan";
        }
    }
    $log->debug("Message has source of : ".Dumper($source));
    return [$source];
}

sub get_subject {
    my $self    = shift;
    my $id      = shift;
    my $imap    = $self->imap_client;
    my $log     = $self->log;

    my $string  = $imap->message_string($id);
    my $msg     = Courriel->parse( text => $string );
    my $subject = $msg->subject();
    
    $log->debug("Message has subject of ".Dumper($subject));

    return $subject;
}

sub select_parser {
    my $self        = shift;
    my $msg_href    = shift;
    my $class       = "Scot::Bot::Parser::";
    my $log         = $self->log;
    my $mongo       = $self->mongo;

#     $log->debug("Selecting parser based on ".Dumper($msg_href));

    my $source      = join(' ',@{$msg_href->{sources}});
    my $subject     = $msg_href->{subject};
    my $from        = $msg_href->{from};

    $log->debug("SOURCE is $source");

    my @parsers = $mongo->read_documents({
       collection => 'parsers',
       match_ref  => {},
       sort_ref   => {'plugin_id' => 1},
       all => 1
    });

      foreach my $js_parser (@parsers) {
      my $parser_id = $js_parser->parser_id;
      my $match_against = $source;
      if($js_parser->condition_type eq 'subject') {
          $match_against = $subject;
      }
          if($js_parser->condition_comparator eq 'equals') {
              if($js_parser->condition_match eq $match_against) {
		$class = 'js::'.$parser_id;
		return $class;
              }
          }elsif($js_parser->condition_comparator eq 'contains') {
              if($js_parser->condition_match =~ /$match_against/) {
		$class = 'js::'.$parser_id;
		return $class;
              }
          }
    }

    unless (defined $source ) { 
        $log->debug("Source in null! ".Dumper($msg_href));
    }

    if ( $source =~ /splunk/ or
         $subject =~ /splunk alert/i ) {
        $msg_href->{source} = "splunk" if ($source eq "NIL");
        $class  .= "Splunk";
    }
    elsif ( $source =~ /workflow/i ) {
        $class  .= "Sep";
    }
    elsif ( $from   =~ /Symantec/i ) {
        $class  .= "Sep2";
    }
    elsif ( $subject =~ /sophos/i ) {
        $class  .= "Sophos";
    }
    elsif ( $subject =~ /auto generated email/i ) {
        $class  .= "Sourcefire";
    }
    elsif ( $subject  =~ /microsoft forefront/i ) {
        $class  .= "Forefront";
    }
    elsif ( $source =~ /fireeye/i or $from =~ /fireeye/i) {
        $class  .= "FireEye";
    }
    else {
        $class  .= "Generic";
    }

    $log->debug("Message class is $class");
    return $class;
}

sub permitted_sender {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->log;

    $log->debug("Permitted sender?");

    my $from    = $href->{from};
    (my $addr = $from)  =~ s/.*<(\S+)>/$1/;
    my ($sender, $domain) = split(/\@/, $addr, 2);

    $log->debug("Checking to see if $sender from $domain is permitted");


    my $mongo   = $self->env->mongo;
    my $cursor  = $mongo->read_documents({
        collection  => "permittedsenders",
        match_ref   => {},
    });
    # if no permitted sender list, allow everybody
    if ( $cursor->count == 0 ) {
        return 1;
    }

    while ( my $permitted_obj = $cursor->next ) {
        my $p_sender    = $permitted_obj->sender;
        my $p_domain    = $permitted_obj->domain;

        if ( defined $p_sender && $p_sender != '' ) {
            if ( $sender =~ m/$p_sender/ ) {
                if ( $domain =~ m/$p_domain/ ) {
                    return 1;
                }
            }
        }
        else {
            if ( $domain =~ m/$p_domain/ ) {
                return 1;
            }
        }
    }
    return undef;
}

sub extract_body {
    my $self    = shift;
    my $imap_id = shift;
    my $log     = $self->log;

    $log->debug("Extracting Body from message $imap_id");

    my $msgstring   = $self->imap_client->message_string($imap_id);
    my $email       = Courriel->parse( text => $msgstring );
    my $htmlpart    = $email->html_body_part();
    my $plainpart   = $email->plain_body_part();
    my $bodyhref;
    if ( $htmlpart ) {
        $bodyhref->{html}    = $htmlpart->content();
    }
    if ( $plainpart ) {
        $bodyhref->{plain}   = $plainpart->content();
    }
    $log->debug("Got these bodyparts: ".Dumper($bodyhref));
    return $bodyhref;
}



__PACKAGE__->meta->make_immutable;

1;
