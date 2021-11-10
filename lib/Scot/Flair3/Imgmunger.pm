package Scot::Flair3::Imgmunger;

use strict;
use warnings;
use utf8;
use lib '../../../lib';
use Moose;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;
use HTML::Element;
use HTML::TreeBuilder;

has io  => (
    is          => 'ro',
    isa         => 'Scot::Flair3::Io',
    required    => 1,
);

sub process_body ($self, $id, $body) {
    my $tree    = $self->build_tree($body);
    $self->process_images($id, $tree);
    my $new     = $self->clean_html($tree);
    return $new;
}

sub build_tree ($self, $html) {
    my $tree = HTML::TreeBuilder->new;
       $tree ->implicit_tags(1);
       $tree ->p_strict(1);
       $tree ->no_space_compacting(1);
       $tree ->parse_content($html);
       $tree ->elementify;
    return $tree;
}

sub process_images ($self, $id, $tree) {
    my @images  = @{ $tree->extract_links('img') };
    my @files   = ();

    IMG:
    foreach my $img_aref (@images) {
        my ($uri, $element, $attr, $tag) = @{$img_aref}; # slice destructuring

        next if $uri =~ /^\/cached_images\//;

        $self->io->log->debug("Working $uri, $element, $attr, $tag");

        my $tmpfile = $self->io->create_file_from_uri($uri);
        if ( ! defined $tmpfile ) {
            $self->io->log->error("FAILED to GET $uri!  Skipping...");
            next IMG;
        }
        my $newfile = $self->io->build_new_name($id, $tmpfile);
        $self->io->move_file($tmpfile, $newfile);
        my $newuri  = $self->io->build_new_uri($newfile);
        $self->rewrite_img_element($element, $newuri, $uri);
    }
}

sub rewrite_img_element ($self, $img, $newuri, $olduri) {
    my $log     = $self->io->log;
    my $alt     = $img->attr('alt');
    $alt    = 'no original alt' if ! defined $alt;
    if ($olduri =~ /^data:/ ) {
        $olduri    = 'Embedded ';
        $alt        = 'dataUri';
    }
    my $newalt  = "Cached $olduri ($alt)";
    my $newimg  = HTML::Element->new(
        'img',
        'src'   => $newuri,
        'alt'   => $newalt,
    );
    $log->debug("New IMG = ",{filter=>\&Dumper, value=>$newimg});

    $img->replace_with($newimg);
}

sub clean_html ($self, $tree) {
    my $body    = $tree->look_down('_tag', 'body');
    my $new     = HTML::Element->new('body');
    $new->push_content($body->detach_content);
    return $new->as_HTML;
}



1;
