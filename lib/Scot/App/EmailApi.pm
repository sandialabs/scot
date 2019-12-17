use strict;
use warnings;

package Scot::App::EmailApi;

use lib '../../../lib';

use Data::Dumper;
use DateTime;
use Try::Tiny;
use Scot::Env;
use Scot::Util::Imap;
use HTML::TreeBuilder;

use Moose;
extends 'Scot::App';

has imap    => (
    is          => 'ro',
    isa         => 'Scot::Util::Imap',
    required    => 1,
    builder     => '_build_imap',
);

sub _build_imap {
    my $self    = shift;
    return $self->env->imap;
}

has sender_whitelist => (
    is              => 'ro',
    isa             => 'ArrayRef',
    required        => 1,
    builder         => "_build_sender_whitelist",
);

sub _build_sender_whitelist {
    my $self    = shift;
    my $attr    = "sender_whitelist";
    my $default = [ 
        'tbruner@sandia.gov',
    ];
    my $envname = "scot_app_emailapi_senderwhitelist";
    return $self->get_config_value($attr, $default, $envname);
}

sub run {
    my $self    = shift;
    my $log     = $self->log;

    $log->debug("Starting Processing of emailapi");

    try {
        $self->process_inbox;
    }
    catch {
        $log->error("Error: $_");
    };
}

sub process_inbox {
    my $self    = shift;
    my $log     = $self->log;
    my $cursor  = $self->fetch_messages;
    my $count   = $cursor->count;

    if ( $count < 1 ) {
        $log->logdie("No Messages returned from IMAP Server");
    }

    while ( my $uid = $cursor->next ) {
        my $msg = $self->imap->get_message($uid);
        # $log->debug("msg is ",{filter=>\&Dumper, value=> $msg});
        $self->process_message($msg);
    }
}

sub fetch_messages {
    my $self    = shift;
    return $self->imap->get_unseen_cursor;
}

has thing   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    builder     => '_build_thing',
);

sub _build_thing {
    my $self    = shift;
    my $attr    = "thing";
    my $default = "event";
    my $envname = "scot_app_emailapi_thing";
    return $self->get_config_value($attr, $default, $envname);
}

sub process_message {
    my $self    = shift;
    my $msg     = shift;
    my $log     = $self->log;
    my $mongo   = $self->env->mongo;

    my $thing   = $self->thing;
    my $sender  = $self->get_sender($msg);
    my $html    = $self->get_html($msg);
    my $tree    = $self->build_html_tree($html);
    my $tags    = $self->get_tags($tree);
    my $sources = $self->get_sources($tree);
    my $subject = $self->get_subject($tree, $msg);
    my $entry   = $self->get_entry($tree);

    my $href    = {
        owner   => $sender,
        subject => $subject,
        tag     => $tags,
        source  => $sources,
        status  => 'open',
        groups  => $self->env->default_groups,
    };
    $self->log->debug("creating : ",{filter=>\&Dumper, value => $href});
    my $obj     = $mongo->collection(ucfirst($thing))->create($href);
    $self->log->debug("entry: ", {filter=>\&Dumper, value => $entry});

    if ( defined $obj ) {
        my $entry   = $mongo->collection('Entry')->create({
            body        => $entry,
            target_id   => $obj->id,
            target_type => $thing,
        });
        if ( defined $entry ) {
            # notify scot via activemq
            $self->env->mq->send("/topic/scot", {
                action  => "created",
                data    => { type => $thing, id => $obj->id, who => $sender },
            });
            # add history
            $mongo->collection('History')->add_history_entry({
                who     => $sender,
                what    => "created $thing via email",
                when    => time(),
                target  => {
                    id  => $obj->id,
                    type    => $thing,
                },
            });
            $log->debug("created event ".$obj->id." and entry ".$entry->id);

            # send an acknowledgement email?
        }
    }
    else {
        die "Failed to create $thing!";
    }
}

sub get_sender {
    my $self    = shift;
    my $msg     = shift;
    my $from    = $msg->{from};
    (my $addr = $from ) =~ s/.* \<(.*)\>/$1/;
    return $addr;
}

sub get_html {
    my $self    = shift;
    my $msg     = shift;
    return $msg->{body_html};
}

sub get_value {
    my $self    = shift;
    my $tree    = shift;
    my $type    = shift;
    my $log     = $self->log;
    # first table in html email must contain scot data
    $log->debug("looking for $type in table");
    my $table   = ( $tree->look_down('_tag', 'table') )[0];
    if ( ! defined $table ) {
        die "Table Not Found in Email";
    }
    my @cells   = $table->look_down('_tag','td');
    for (my $i = 0; $i < scalar(@cells); $i += 2) {
        my $key = $cells[$i]->as_text;
        my $val = $cells[$i+1]->as_text;
        $log->debug("cell[$i] = $key");
        $log->debug("cell[$i+1] = $val");
        if ( $key =~ /$type/i ) {
            if ( grep { /$type/ } (qw(tag source)) ) {
                my @tags = split(/[ ]*,[ ]*/,$val);
                return wantarray ? @tags : \@tags;
            }
            else {
                return $val;
            }
        }
    }
    return undef;
}

sub get_tags {
    my $self    = shift;
    my $tree    = shift;
    return $self->get_value($tree, "tag");
}

sub get_sources {
    my $self    = shift;
    my $tree    = shift;
    return $self->get_value($tree, "source");
}

sub get_subject {
    my $self    = shift;
    my $tree    = shift;
    my $msg     = shift;
    return $self->get_value($tree, "subject") // $msg->{subject};
}

sub get_entry {
    my $self    = shift;
    my $tree    = shift;
    # remove the scot table with tags,etc.
    my $table   = ( $tree->look_down('_tag', 'table') )[0];
    $table->detach();
    # return as html
    return $tree->as_HTML;
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
