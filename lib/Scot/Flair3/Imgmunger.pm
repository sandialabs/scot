package Scot::Flair3::Imgmunger;

use strict;
use warnings;
use utf8;
use lib '../../../lib';
use Moose;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;
use DateTime;
use File::Path qw(make_path);
use HTML::Element;
use HTML::TreeBuilder;
use Scot::Flair3::Web;

has io  => (
    is          => 'ro',
    isa         => 'Scot::Flair3::Io',
    required    => 1,
);

has web => (
    is          => 'ro',
    isa         => 'Scot::Flair3::Web',
    required    => 1,
    default     => sub { Scot::Flair3::Web->new(); },
);

has image_root  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '/opt/scotfiles/cached_images',
);

has default_dir_mode => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '0755',
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

sub get_image_destination ($self, $id) {
    my $dt  = DateTime->now();
    my $y   = $dt->year;
    my $dir = join('/', $self->image_root, $id);
    return $dir;
}

sub ensure_dir_exists ($self, $dir) {
    return if (-d $dir);
    my $err;
    my $opts = {
        error   => \$err,
        mode    => $self->default_dir_mode,
    };
    make_path($dir, $opts);
}

sub process_images ($self, $id, $tree) {
    my $web     = $self->web;
    my @images  = @{ $tree->extract_links('img') };
    my @files   = ();

    $self->io->log->info("Beginning Imgmunger...");

    IMG:
    foreach my $img_aref (@images) {
        my ($uri, $element, $attr, $tag) = @{$img_aref}; # slice destructuring

        if ($uri =~ /^\/cached_images\//) {
            $self->io->log->trace("skipping previously cached image $uri");
            next;
        }
        $self->io->log->debug("Working $uri, $element->as_HTML, $attr, $tag");

        # note need check /branch for data uri

        my $dest      = $self->get_image_destination($id);
        $self->ensure_dir_exists($dest);
        my $imagefile = $web->get_image($uri, $dest);

        if ( ! defined $imagefile ) {
            $self->io->log->error("FAILED to GET $uri!  Skipping...");
            next IMG;
        }
        $self->io->log->debug("Downloaded $imagefile");
        my $newuri    = $self->build_new_uri($imagefile, $dest);
        $self->rewrite_img_element($element, $newuri, $uri);
    }
}

sub build_new_uri ($self, $file, $dest) {
    $file =~ m{^$dest(.*)$};
    return $1;
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
    $log->trace("New IMG = ",{filter=>\&Dumper, value=>$newimg});

    $img->replace_with($newimg);
}

sub clean_html ($self, $tree) {
    my $body    = $tree->look_down('_tag', 'body');
    my $new     = HTML::Element->new('body');
    $new->push_content($body->detach_content);
    return $new->as_HTML;
}



1;
