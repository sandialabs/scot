package Scot::Email::Parser::PassThrough;

use lib '../../../../lib';
use HTML::TreeBuilder;
use HTML::FormatText;
use HTML::Element;
use Data::Dumper;
use Moose;
extends 'Scot::Email::Parser';

=head1 Scot::Email::Parser::Passthrough

This parser is designed to parse an email message and insert
an event with entries for the message body and attachments into SCOT

=cut

sub get_sourcename {
    return "";
}

sub will_parse {
    my $self    = shift;
    my $href    = shift;
    my $from    = $href->{from};
    my $subject = $href->{subject};
    # works for everything!
    return 1;
}

sub parse_message {
    my $self    = shift;
    my $message = shift;
    my $log     = $self->env->log;

    $log->debug("Parsing SCOT Passthrough email");

    my $body    = $self->normalize_body($message);
    my $tree    = $self->build_html_tree($body);

    if ( ! defined $tree ) {
        $log->error("Unable to parse message body!",
                    { filter => \&Dumper, value => $message });
        return undef;
    }

    my $from        = $message->{from};
    my $subject     = $message->{subject};
    my $attachments = $message->{attachments};
    my $received    = $message->{received};

    my $stripfrom;

    ($stripfrom = $from) =~ s/.* <(.*)>/$1/;
    $stripfrom =~ s/ /_/g;

    my @tags = ();

    $log->debug("attachments?");
    if ( defined $attachments ) {
        $log->debug("    yes, with");
        foreach my $ak (%$attachments) {
            $log->debug("     $ak") if defined $attachments->{$ak};
        }
        push @tags, "attachment";
    }

    if ( $message->{images} ) {
        $self->inline_images($message->{images}, $tree);
    }

    my $html = $tree->as_HTML;
    my $msg_html_body = $self->detach_html_body($tree);
    my $plain_text  = $self->get_plain_text($message,$tree);

    my %json    = (
        event   => {
            subject     => $subject,
            created     => $received,
            owner       => 'scot-admin',
            source      => [ 'email', $stripfrom ],
            tag         => \@tags,
            status      => 'open',
            groups      => $self->env->default_groups,
            data        => {
                message_id  => $message->{message_id},
            }
        },
        entry       => {
            body_plain  => $plain_text,
            body        => $html,
        },
        attachments => $attachments,
    );

    return wantarray ? %json : \%json;
}

sub get_plain_text {
    my $self    = shift;
    my $message = shift;
    my $tree    = shift;
    my $log     = $self->env->log;

    my $plain_text = $message->{body_plain};
    if ( ! $plain_text ) {
        $plain_text = $self->get_plain_text_from_tree($tree);
    }

    if ( ! $plain_text ) {
        $log->error("Unable to find plain text from : ",{filter=>\&Dumper, value=>$message});
    }
    return $plain_text;
}

sub detach_html_body {
    my $self    = shift;
    my $tree    = shift;
    my $body    = $tree->look_down('_tag', 'body');
    my $div     = HTML::Element->new('div');
    $div->push_content($body->detach_content);
    return $div->as_HTML();
}

sub get_plain_text_from_tree {
    my $self    = shift;
    my $tree    = shift;
    my $format  = HTML::FormatText->new();
    return $format->format($tree);
}

sub normalize_body {
    my $self    = shift;
    my $message = shift;
    my $log     = $self->env->log;
    my $body    = $message->{body_html};
    # add data norming here if necessary
    if ( ! defined $body ) {
        $log->debug("using body");
        $body   = $message->{body};
    }

    if ( ! defined $body ) {
        $log->debug("using body_plain");
        $body   = $message->{body_plain};
    }
    $log->trace("BODY => $body");
    return $body;
}


sub inline_images {
    my $self    = shift;
    my $images  = shift;
    my $tree    = shift;
    my $log     = $self->env->log;

    # now the hard stuff

    my @imgtags = $tree->look_down('_tag', 'img');
    foreach my $it (@imgtags) {
        my $src     = $it->attr('src');
        (my $name = $src) =~ s/cid:(.*)@.*/$1/;
        $log->debug("replacing $src img with $name");
        my $newimg  = $images->{$name};
        $it->replace_with($newimg);
    }
}

1;
