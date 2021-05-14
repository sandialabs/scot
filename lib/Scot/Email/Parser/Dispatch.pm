package Scot::Email::Parser::Dispatch;

use strict;
use warnings;
use Moose;
use HTML::Element;
use URI;

extends 'Scot::Email::Parser';

sub parse {
    my $self    = shift;
    my $msg     = shift;

    my ($courriel, $html, $plain) = $self->get_body($msg->{message_str});

    if ( $self->body_not_html($html)) {
        $html   = $self->wrap_non_html($html);
    }

    my $tree        = $self->build_html_tree($html);
    my $attachments = $self->handle_attachments($courriel, $msg, $tree);
    my $entry_data  = $self->build_entry($tree);


    my %json    = (
        dispatch    => {
            subject     => $msg->{subject},
            source      => [ 'email', $msg->{from} ],
            tag         => [ '' ],
            status      => 'open',
            data        => {
                message_id  => $msg->{message_id},
            },
        },
        entry       => $entry_data,
        attachments => $attachments,
    );

    return wantarray ? %json : \%json;
}

sub build_entry {
    my $self    = shift;
    my $tree    = shift;
    # $tree->dump();
     
    # hack
    no warnings;
    my $new     = $tree->as_HTML;
    my $href    = {
        body    => $new
    };

    my $tlp = $self->find_tlp($new);
    if (defined $tlp ) {
        $href->{tlp} = $tlp;
    }

    return $href;
}

sub find_tlp {
    my $self    = shift;
    my $text    = shift;

    foreach my $line (split(/\n/,$text)) {
        (my $level) = ($line =~ m/TLP:(.*) DOE/);
        if ( defined $level ) {
            return lc($level);
        }
    }
}

sub handle_attachments {
    my $self        = shift;
    my $courriel    = shift;
    my $msg         = shift;
    my $tree        = shift;

    # imbed images into html
    my %images  = $self->get_images($courriel);
    $self->inline_images($tree, \%images);

    # don't know how to handle yet
    # and not sure we want to support this for dispatches
    # my %remainder   = $self->get_non_image_attachments($courriel);
    my %remainder = ();

    return wantarray ? %remainder : \%remainder;

}

sub get_images {
    my $self        = shift;
    my $courriel    = shift;

    my %images  = ();

    foreach my $part ($courriel->parts()) {
        my $mime    = $part->mime_type;
        next unless ($mime =~ /image/);
        my $encoding    = $part->encoding;
        my $content     = $part->content;
        my $filename    = $part->filename;
        $images{$filename} = $self->build_img_element($mime, $content, $filename);
    }
    return wantarray ? %images : \%images;
}

sub get_non_image_attachments {
    my $self        = shift;
    my $courriel    = shift;
    my $log         = $self->env->log();

    my %attachments = ();

    my $index = 0;
    foreach my $part ($courriel->parts()) {
        my $mime        = $part->mime_type;
        next if ($mime =~ /image/); # already handled them
        my $encoding    = $part->encoding;
        my $filename    = $part->filename;
        my $content     = $part->content;
        my $debugmsg    = join('\n', 
            '',
            "Part    : $index",
            "Filename: $filename",
            "Encoding: $encoding",
            "Size    : ".length($content),
            ''
        );
        $log->debug($debugmsg);
        if ( $filename ) {
            $attachments{$filename} = {
                encoding    => $encoding,
                content     => $content,
            };
        }
    }
    return wantarray ? %attachments : \%attachments;
}

sub build_img_element {
    my ($self, $mime, $content, $filename) = @_;

    $filename = "image" unless defined $filename;
    my $log = $self->env->log;

    $log->debug("Building IMG element");
    $log->debug("File name is $filename");
    $log->debug("Mime is $mime");
    $log->debug("Content size: ".length($content));

    my $uri = URI->new("data:");
    $uri->media_type($mime);
    $uri->data($content);
    
    my $element = HTML::Element->new('img', 'src' => $uri, 'alt' => $filename);
    return $element;
}

sub inline_images {
    my $self    = shift;
    my $tree    = shift;
    my $imgdb   = shift;

    # change attached images into data:uri img tags.
    # flair will later change them to local files.

    my @images  = $tree->look_down('_tag', 'img');

    foreach my $image (@images) {
        my $src     = $image->attr('src');
        (my $name = $src) =~ s/cid:(.*)@.*/$1/;
        my $new = $imgdb->{$name};
        $image->replace_with($new);
    }
}

1;



