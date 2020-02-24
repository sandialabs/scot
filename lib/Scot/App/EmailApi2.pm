use strict;
use warnings;

package Scot::App::EmailApi2;

use lib '../../../lib';
use Data::Dumper;
use DateTime;
use Try::Tiny;
use Try::Tiny::Retry qw/:all/;
use Scot::Env;
use HTML::TreeBuilder;
use Mail::IMAPClient;
use Courriel;
use URI;

use Readonly;
Readonly my $MSG_ID_FMT =>qr/\A\d+\z/;

use Moose;
extends 'Scot::App';

has imap_config => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    builder     => '_build_imap_config',
);

sub _build_imap_config {
    my $self    = shift;
    my $attr    = 'imap_config';
    my $envname = 'email_api_imap_config';
    my $default = {
        hostname    => 'localhost',
        port        => 993,
        mailbox     => 'INBOX',
        username    => 'scotcoe-events',
        password    => 'changeme',
        ssl         => [ 'SSL_verify_mode', 0 ],
        uid         => 1,
        ignore_size_errors  => 1,
    };
    return $self->get_config_value($attr, $default, $envname);
}

has _client_pid => (
    is          => 'rw',
    isa         => 'Num',
    default     => sub { $$ },
);

has imap_client => (
    is          => 'ro',
    isa         => 'Mail::IMAPClient',
    required    => 1,
    lazy        => 1,
    builder     => '_build_imap_client',
    clearer     => 'clear_client',
);

sub _build_imap_client {
    my $self    = shift;
    my $log     = $self->log;
    my @options = (
        Server              => $self->imap_config->{hostname},
        Port                => $self->imap_config->{port},
        User                => $self->imap_config->{username},
        Password            => $self->imap_config->{password},
        Ssl                 => $self->imap_config->{ssl},
        Uid                 => $self->imap_config->{uid},
        Ignoresizeerrors    => $self->imap_config->{ignore_size_errors},
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
    # $log->debug("client ",{filter=>\&Dumper, value=> $client});
    return $client;
}

sub reconnect_if_forked {
    my $self    = shift;
    my $log     = $self->log;

    if ( $$ != $self->_client_pid ) {
        $log->debug("Fork detected, reconnection to IMAP server");
        $self->_client_pid($$);
        $self->clear_client;
    }
    return;
}

has whitelist   => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    builder     => '_build_whitelist',
);

sub _build_whitelist {
    my $self    = shift;
    my $attr    = "sender_whitelist",
    my $default = [
        'tbruner@sandia.gov',
    ];
    my $envname = 'scot_app_emailapi_sender_whitelist';
    return $self->get_config_value($attr, $default, $envname);
}

sub run {
    my $self    = shift;
    my $log     = $self->log;
    my $peek    = $self->imap_config->{peek} // 0;

    $log->debug("Starting EmailApi2 Processing");

    my @unseen_uids = $self->get_new_uids;
    # my @unseen_uids = $self->get_recent_uids;

    $log->debug(scalar(@unseen_uids)." Unread Messages in inbox");

    foreach my $uid (@unseen_uids) {
        my $email = $self->get_email($uid, $peek);
        $self->process_email($email);
    }
}

sub get_new_uids {
    my $self    = shift;
    my $log     = $self->log;
    my $client  = $self->imap_client;
    $self->reconnect_if_forked;

    my $inbox   = $self->imap_config->{mailbox};
    $log->debug("retrieving unseen mail in $inbox");

    $client->select($inbox);
    my @unread  = ();

    retry {
        @unread = $client->unseen;
    }
    on_retry {
        $self->clear_client;
    }
    catch {
        $log->logdie("Failed to get unseen Messges");
    };

    $log->debug("unseen:",{filter=>\&Dumper,value=>\@unread});
    return wantarray ? @unread : \@unread;
}

sub get_recent_uids {
    my $self    = shift;
    my $client  = $self->imap_client;
    $self->reconnect_if_forked;

    my $inbox = $self->imap_config->{mailbox};
    $client->select($inbox);

    my @uids = ();

    $client->Peek(1);

    my $since = time() - (60 * 60 * 1);

    foreach my $mid ($client->since($since)) {
        if ( $mid =~ $MSG_ID_FMT ) {
            push @uids, $mid;
        }
    }
    return wantarray ? @uids : \@uids;
}

sub get_email {
    my $self    = shift;
    my $uid     = shift;
    my $peek    = shift;
    my $log     = $self->log;

    $self->reconnect_if_forked;

    $log->debug("retrieving uid $uid");
    
    my $envelope = $self->build_envelope($uid);

    $log->debug("Envelope: ",{filter=>\&Dumper, value => $envelope});

    my $message = $self->build_message($uid, $envelope);

    return $message;
}

sub build_envelope {
    my $self    = shift;
    my $uid     = shift;
    my $log     = $self->log;

    my $envelope = retry {
        $self->imap_client->get_envelope($uid);
    }
    on_retry {
        $self->clear_client;
    }
    catch {
        $log->error("IMAP Error: $_");
    };
    return $envelope;
}

sub build_message {
    my $self        = shift;
    my $uid         = shift;
    my $envelope    = shift;
    my $log         = $self->log;

    my $parsedemail = Courriel->parse(
        text    => $self->imap_client->message_string($uid)
    );

    my %message     = (
        imap_uid    => $uid,
        envelope    => $envelope,
        subject     => $self->get_subject($uid),
        from        => $self->get_from($envelope),
        to          => $self->get_to($envelope),
        when        => $self->get_when($parsedemail),
        message_id  => $self->get_message_id($parsedemail),
    );
    $log->debug("------------ MESSAGE ------------------");
    $log->debug({filter => \&Dumper, value => \%message });

    $message{body_html}         = $self->get_body_html($parsedemail);
    $message{body_plain}        = $self->get_body_plain($parsedemail);
    $message{attached_images}   = $self->get_attached_images($parsedemail);

    # $log->debug({filter => \&Dumper, value=> $message{attached_images}});
    $log->debug("------------ ------- ------------------");
    return wantarray ? %message : \%message;
}

sub get_subject {
    my $self    = shift;
    my $uid     = shift;
    $self->reconnect_if_forked;
    my $client  = $self->imap_client;
    my $log     = $self->log;
    my $subject = retry {
        $client->subject($uid);
    }
    on_retry {
        $self->clear_client;
    }
    catch {
        $log->error("Failed to get Subject: $_");
    };
    return $subject;
}

sub get_from {
    my $self    = shift;
    my $envelope= shift;
    return $envelope->from_addresses;
}

sub get_to {
    my $self    = shift;
    my $envelope= shift;
    return join(', ', $envelope->to_addresses);
}

sub get_when {
    my $self    = shift;
    my $email   = shift;

    my $dt  = $email->datetime();
    return $dt->epoch;
}

sub get_message_id {
    my $self    = shift;
    my $email   = shift;
    my $headers = $email->headers;
    return $headers->get('Message-Id');
}

sub get_body_html {
    my $self    = shift;
    my $email   = shift;
    my $htmlpart    = $email->html_body_part;
    if ( $htmlpart ) {
        return $htmlpart->content;
    }
}

sub get_body_plain {
    my $self    = shift;
    my $email   = shift;
    my $plainpart   = $email->plain_body_part;
    if ( $plainpart ) {
        return $plainpart->content;
    }
}

sub get_attached_images {
    my $self    = shift;
    my $email   = shift;
    my $log     = $self->log;

    $log->debug("looking for attached/inline images");

    my %images  = ();

    $log->debug("number of parts = ", $email->part_count());

    foreach my $part ($email->parts()) {
        my $mime    = $part->mime_type;
        next unless ($mime =~ /image/);
        my $encoding    = $part->encoding;
        my $content     = $part->content();
        my $filename    = $part->filename();
        $images{$filename} = $self->build_img($mime, $content, $filename);
    }
    return wantarray ? %images : \%images;
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

sub process_email {
    my $self    = shift;
    my $email   = shift;
    my $log     = $self->log;
    my $html    = $email->{body_html};
    my $tree    = $self->build_html_tree($html);
    my $scottbl = ($tree->look_down('_tag','table'))[0]->detach_content;

    my ( $subject,
         $tags,
         $sources ) = $self->get_event_basics($scottbl);

    my $sender  = $email->{from};

    my $event_data  = {
        owner       => $sender,
        subject     => $subject // $email->{subject},
        tag         => $tags,
        source      => $sources,
        status      => 'open',
        groups      => $self->env->default_groups,
    };

    $self->inline_images($email, $tree);



    my $event   = $self->env->mongo->collection('Event')->create($event_data);
    if (defined $event ) {
        my $entry_data  = {
            body    => $tree->as_HTML,
            target  => {
                id      => $event->id,
                type    => "event",
            },
            groups  => $self->env->default_groups,
        };
        my $entry = $self->env->mongo->collection('Entry')->create($entry_data);
        if ( defined $entry ) {
            $self->env->mq->send("/topic/scot",{
                action  => "created",
                data    => { type => "entry", id => $entry->id, who => $sender },
            });
            $self->env->mongo->collection('History')->add_history_entry({
                who     => $sender,
                what    => "created event via email",
                when    => time(),
                target  => {
                    id      => $event->id,
                    type    => "event",
                }
            });
            $event->update({ '$inc' => { entry_count => 1 } });
        }
        else {
            $log->error("failed entry creation");
        }
    }
    else {
        $log->error("failed event creation");
    }
}

sub inline_images {
    my $self    = shift;
    my $email   = shift;
    my $tree    = shift;
    my $log     = $self->log;

    # now the hard stuff
    my $images  = $email->{attached_images};

    my @imgtags = $tree->look_down('_tag', 'img');
    foreach my $it (@imgtags) {
        my $src     = $it->attr('src');
        (my $name = $src) =~ s/cid:(.*)@.*/$1/;
        $log->debug("replacing $src img with $name");
        my $newimg  = $images->{$name};
        $it->replace_with($newimg);
    }
}

sub get_event_basics {
    my $self    = shift;
    my $table   = shift;
    my @cells   = $table->look_down('_tag', 'td');
    my $subject;
    my $tags;
    my $sources;
    for ( my $i = 0; $i < scalar(@cells); $i += 2) {
        my $key;
        my $val;
        my $j   = $i+1;

        if ( defined $cells[$i] and ref($cells[$i]) eq "HTML::Element" ) {
            $key    = $cells[$i]->as_text;
        }
        if ( defined $cells[$j] and ref($cells[$j]) eq "HTML::Element" ) {
            $val    = $cells[$j]->as_text;
        }
        if (lc($key) eq "subject") {
            $subject = $val;
            next;
        }
        if (lc($key) eq "sources") {
            $sources = [ split(/[ ]*,[ ]*/,$val) ];
        }
        if (lc($key) eq "tags") {
            $tags    = [ split(/[ ]*,[ ]*/,$val) ];
        }
    }
    return $subject, $tags, $sources;
}

sub build_html_tree {
    my $self    = shift;
    my $body    = shift;
    my $log     = $self->log;
    my $tree    = HTML::TreeBuilder->new;
    $tree       ->implicit_tags(1);
    $tree       ->implicit_body_p_tag(1);
    $tree       ->parse_content($body);

    unless ( $tree ) {
        $log->error("Body = $body");
        $log->logdie("Unable to Parse HTML!");
    }
    return $tree;
}

1;
