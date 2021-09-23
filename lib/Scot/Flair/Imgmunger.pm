package Scot::Flair::Imgmunger;

use strict;
use warnings;
use lib '../../../../lib';

use HTML::TreeBuilder;
use HTML::Element;
use Moose;

has env => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required=> 1,
);

has scotio => (
    is      => 'ro',
    isa     => 'Scot::Flair::Io',
    required=> 1,
);

sub process_body {
    my $self    = shift;
    my $id      = shift;
    my $body    = shift;
    my $log     = $self->env->log;

    $log->debug("processing body for images");

    my $tree    = $self->build_tree($body);
    my @files   = $self->process_images($id, $tree);
    my $newbody = $self->clean_html($tree);
    return $newbody;
}

sub build_tree {
    my $self    = shift;
    my $html    = shift;

    my $tree = HTML::TreeBuilder->new;
       $tree ->implicit_tags(1);
       $tree ->p_strict(1);
       $tree ->no_space_compacting(1);
       $tree ->parse_content($html);
       $tree ->elementify;

    return $tree;
}

sub process_images {
    my $self    = shift;
    my $id      = shift;
    my $tree    = shift;
    my @images  = @{$tree->extract_links('img')};
    my @files   = ();
    my $log     = $self->env->log;

    $log->debug("process_image links");

    foreach my $img_aref (@images) {

        my ( $link, $element, $attr, $tag ) = @{$img_aref};

        $log->debug("link = $link");

        if ( $link =~ /^\/cached_images\// ) {
            $log->debug("Image already cached.");
            next;
        }

        my ( $fqn, $fname, $origname );

        if ( $link =~ m/^data:/ ) {
            $log->trace("data uri detected");
            ($fqn, $fname) = $self->extract_data_image($link, $id);
        }
        else {
            ($fqn, $fname, $origname) = $self->download_image($link, $id);
        }
        push @files, {
            fqn         => $fqn,
            fname       => $fname,
            origname    => $origname
        };
        $self->update_html($element, $fqn, $fname, $origname);
    }
    return wantarray ? @files : \@files;
}

sub clean_html {
    my $self    = shift;
    my $tree    = shift;
    my $body    = $tree->look_down('_tag', 'body');
    my $newbody     = HTML::Element->new('body');
    $newbody->push_content($body->detach_content);
    return $newbody->as_HTML;
}

sub update_html {
    my $self    = shift;
    my $element = shift;
    my $fqn     = shift;
    my $name    = shift;
    my $orig    = shift // 'datauri';
    my $log     = $self->env->log;

    $log->debug("updating html with fqn = $fqn name = $name orig = $orig");

    if (! defined $fqn or ! defined $name or ! defined $orig ) {
        $log->error("FAILED retrieving remote image. skipping replacement in body");
        return;
    }

    my $location = (split(/cached_images\//, $fqn))[-1];

    # $log->debug("Location is $location");

    my $source  = join('/', '/cached_images', $location);

    $log->debug("New source for image: $source");

    my $alt     = $element->attr('alt');
    $alt = (defined $alt) ? 
        "Scot Copy of $orig" :
        "Scot Cached Image of $orig";
    my $newimg  = HTML::Element->new(
        'img', 'src' => $source, 'alt' => $alt
    );
    $element->replace_with($newimg);
    $log->debug("New element ".$element->as_HTML());
}

sub extract_data_image {
    my $self    = shift;
    my $link    = shift;
    my $id      = shift;
    my $io      = $self->scotio;
    my $log     = $self->env->log;

    my ($fqn, $fname) = $io->save_data_uri($link, $id);
    return $fqn, $fname;
}

sub download_image {
    my $self    = shift;
    my $link    = shift;
    my $id      = shift;
    my $io      = $self->scotio;
    my $log     = $self->env->log;

    $log->debug("Attempting to download: $link $id");

    my ($fqn, $fname, $orig) = $io->download($link, $id);

    $log->debug("Download results: fqn = $fqn fname = $fname orig => $orig");

    return $fqn, $fname, $orig;
}

1;

