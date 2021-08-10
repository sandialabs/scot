package Scot::Email::Parser::Event;

use strict;
use warnings;
use Data::Dumper;
use HTML::Element;
use URI;
use Moose;

extends 'Scot::Email::Parser';

sub parse {
    my $self    = shift;
    my $msg     = shift;

    my ($courriel, $html, $plain) = $self->get_body($msg->{message_str});

    if ( $self->body_not_html($html)) {
        $html   = $self->wrap_non_html($html);
    }

    my $tree        = $self->build_html_tree($html);

    my $subject     = $msg->{subject};
    my $tags        = [];
    my $sources     = [ 'email', $msg->{from} ];

    if ( $self->is_event_api($tree) ) {
        ($subject,
         $tags,
         $sources) = $self->get_api_basics($tree);
    }


    my $attachments = $self->handle_attachments($courriel, $msg, $tree);
    my $entry_data  = $self->build_entry($tree);


    my %json    = (
        event    => {
            subject     => $subject,
            source      => $sources,
            tag         => $tags,
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

sub is_event_api {
    my $self    = shift;
    my $tree    = shift;

    # scot email api relies on the first table in email having
    # a certain format

    my $table   = ($tree->look_down('_tag','table'))[0];
    return undef if ( ! defined $table );
        
    my @cells   = $table->look_down('_tag','td');
    my @needed_elements = qw(subject sources tags);
    my %found   = ();

    foreach my $cell (@cells) {
        my $text = $cell->as_text;
        if ( grep {/$text/i} @needed_elements ) {
            $found{$text}++;
        }
    }
    return ( $found{subject} && $found{sources} && $found{tags} );
}

sub get_api_basics {
    my $self    = shift;
    my $tree    = shift;
    my $log     = $self->env->log;
    my $table   = ($tree->look_down('_tag','table'))[0]->detach_content;
    my @cells   = $table->look_down('_tag','td');
    my ($subject, $tags, $sources);

    for (my $i=0; $i < scalar(@cells); $i+=2) {
        my ($key,$val);
        my $j   = $i + 1;

        my $key_cell = $cells[$i];
        my $val_cell = $cells[$j];

        $log->debug("Cell Key = $key_cell");
        $log->debug("Cell Val = $val_cell");

        if ( defined $key_cell and ref($key_cell) eq "HTML::Element" ) {
            $key = lc($key_cell->as_text);
        }
        if ( defined $val_cell and ref($val_cell) eq "HTML::Element" ) {
            $val = lc($val_cell->as_text);
        }
        if ( lc($key) eq "subject" ) {
            $subject = $val;
        }
        if ( lc($key) eq "sources" ) {
            $sources = [ map { lc($_); } split(/[ ]*,[ ]*/, $val) ];
        }
        if ( lc($key) eq "tags" ) {
            $tags    = [ map { lc($_); } split(/[ ]*,[ ]*/, $val) ];
        }
    }
    $log->debug("Subject = $subject Tags = ".join(',',@$tags)." Sources = ".join(',',@$sources));
    return $subject, $tags, $sources;
}

sub build_entry {
    my $self    = shift;
    my $tree    = shift;
    # $tree->dump();
     
    # hack
    no warnings;
    my $new     = $tree->as_HTML;

    return { body => $new };
}

sub handle_attachments {
    my $self        = shift;
    my $courriel    = shift;
    my $msg         = shift;
    my $tree        = shift;
    my $log         = $self->env->log;

    # imbed images into html
    my %images  = $self->get_images($courriel);
    $self->inline_images($tree, \%images);

    # don't know how to handle yet
    # and not sure we want to support this for event
    # my %remainder   = $self->get_non_image_attachments($courriel);
    my @remainder = ();

    foreach my $part ($courriel->parts()) {

        if ( $part->is_attachment ) {
            $log->debug("Found an attachment");
            push @remainder, {
                filename    => $part->filename,
                mime_type   => $part->mime_type,
                multipart   => $part->is_multipart,
                content     => $part->content,
            };
        }
    }

    $log->trace("Found Attachments: ",{filter=>\&Dumper, value=>\@remainder});
          
    return wantarray ? @remainder : \@remainder;

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

sub wrap_non_html {
    my $self    = shift;
    my $html    = shift;
    return qq{<html><body><pre>$html</pre></body></html>};
}

1;



