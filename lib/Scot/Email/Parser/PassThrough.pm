package Scot::Email::Parser::PassThrough;

use lib '../../../../lib';
use HTML::TreeBuilder;
use HTML::FormatText;
use Data::Dumper;
use Moose;
extends 'Scot::Email::Parser';

=head1 Scot::Email::Parser::Passthrough

This parser basically just passes the content of the e-mail to an Alertgroup/alert.

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

    if ( $message->{images} ) {
        $self->inline_images($message->{images}, $tree);
    }

    my $html = $tree->as_HTML;

    my %json    = (
        subject     => $subject,
        message_id  => $message->{message_id},
        body_plain  => $self->get_plain_text($tree),
        body        => $html,
        columns     => [ 'email' ],
        data        => [{ email => $html}],
        source      => [ 'email' ],
        tag         => [],
        ahrefs      => [],
        attachments => $message->{attachments},
    );

    return wantarray ? %json : \%json;
}

sub get_plain_text {
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
