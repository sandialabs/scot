package Scot::Imgmunger::Processor;

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
    isa     => 'Scot::Imgmunger::Io',
    required=> 1,
);

sub process_item {
    my $self    = shift;
    my $json    = shift;
    my $io      = $self->scotio;
    my $log     = $self->env->log;

    my $type    = $json->{data}->{type};
    my $id      = $json->{data}->{id} + 0;

    $log->debug("Processing Item $type $id");

    my $item    = $io->retrieve_item($type, $id);
    my $results = $self->munge_images($item);

    $io->update_item($item, $results->{html});

}


sub munge_images {
    my $self    = shift;
    my $item    = shift;

    my $html    = $item->body_flair;
    return unless $html;

    my $tree    = $self->build_tree($html);
    my @images  = @{$tree->extract_links('img')};
    my @files   = $self->process_images($item, @images);
    my $newhtml = $self->clean_html($tree);
    return {
        html    => $newhtml,
        files   => \@files,
    };
}

sub build_tree {
    my $self    = shift;
    my $html    = shift;

    my $tree = HTML::TreeBuilder->new;
       $tree ->implicit_tags(1);
       $tree ->implicit_body_p_tag(1);
       $tree ->p_strict(1);
       $tree ->no_space_compacting(1);
       $tree ->parse_content($html);
       $tree ->elementify;

    return $tree;
}

sub process_images {
    my $self    = shift;
    my $item    = shift;
    my @images  = @_;
    my $id      = $item->id;
    my @files   = ();

    foreach my $img_aref (@images) {

        my ( $link, $element, $attr, $tag ) = @{$img_aref};
        my ( $fqn, $fname, $origname );

        if ( $link =~ m/^data:/ ) {
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
    my $div     = HTML::Element->new('div');
    $div->push_content($body->detach_content);
    return $div->as_HTML;
}

sub update_html {
    my $self    = shift;
    my $element = shift;
    my $fqn     = shift;
    my $name    = shift;
    my $orig    = shift // 'unknown';

    my $source  = $self->env->html_root;
    my $alt     = $element->attr('alt');
    $alt = (defined $alt) ? 
        "Scot Copy of $orig" :
        "Scot Cached Image of $orig";
    my $newimg  = HTML::Element->new(
        'img', 'src' => $source, 'alt' => $alt
    );
    $element->replace_with($newimg);
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
    my ($fqn, $fname, $orig) = $io->download($link, $id);
    return $fqn, $fname, $orig;
}

1;

