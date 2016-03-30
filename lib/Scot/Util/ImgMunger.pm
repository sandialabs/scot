package Scot::Util::ImgMunger;

use v5.10;
use strict;
use warnings;
# use re 'debug';

use Readonly;
use HTML::TreeBuilder 5 -weak;
use HTML::FormatText;
use HTML::Element;
use Data::Dumper;
use MIME::Base64;
use LWP::UserAgent;
use LWP::Protocol::https;
use File::Slurp;
use Digest::MD5 qw(md5_hex);

use Moose;
use namespace::autoclean;


has env => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
    default     => sub { Scot::Env->instance },
);

has conf => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_get_conf',
);

sub _get_conf {
    my $self    = shift;
    my $env     = $self->env;
    # {
    #   html_root   => 'the / where the webserver finds the cached_images dir
    #   image_dir   => the real dir on the server where to store the file
    #   storage     => local | api
    # }
    my $href    =  $env->get_module_conf('Scot::Util::ImgMunger');
    unless ( defined $href->{html_root} ) {
        $href = {
            html_root   => "/cached_images",
            image_dir   => ".",
            storage     => "local",
        };
    }
    return $href;
}


sub process_html { 
    my $self    = shift;
    my $entry   = shift;    # this is html string
    my $id      = shift;


    return unless $entry;    # nothing to do

    my $tree    = HTML::TreeBuilder->new;
       $tree    ->implicit_tags(1);
       $tree    ->implicit_body_p_tag(1);
       $tree    ->p_strict(1);
       $tree    ->no_space_compacting(1);
       $tree    ->parse_content($entry);
       $tree    ->elementify;

    my @images  = @{ $tree->extract_links('img') };
    my @files   = ();

    foreach my $aref (@images) {
        my ( $link,
            $element,
            $attr,
            $tag   ) = @{ $aref };

        my ($fqn, $fname);

        if ($link =~ m/^data:/) {
            ($fqn,$fname)   =  $self->extract_data_image($link, $id);
        }
        else {
            ($fqn,$fname) = $self->download_image($link);
        }

        $self->update_html($element, $fqn, $fname);
    }

    my $new_html;

    my $body = $tree->look_down('_tag', 'body');
    my $div  = HTML::Element->new('div');
    $div->push_content($body->detach_content);

    return $div->as_HTML;
}

sub extract_data_image {
    my $self    = shift;
    my $link    = shift;
    my $id      = shift;

    $link =~ m/^data:(.*);(.*),(.*)$/;
    my $mimetype = $1;
    my $encoding = $2;
    my $data     = $3;

    $self->env->log->debug("mimetype = $mimetype encoding = $encoding");

    my ( $type, $ext ) = split('/', $mimetype);

    my $decoded         = decode_base64($data);
    my ($fqn, $fname)   = $self->create_file($decoded, $id, $ext);

    return $fqn, $fname;
}

sub download_image {
    my $self    = shift;
    my $link    = shift;
    my $agent   = LWP::UserAgent->new(
        env_proxy   => 1,
        timeout     => 10,
    );
    $agent->ssl_opts( SSL_verify_mode => "SSL_VERIFY_NONE" );
    $agent->proxy(['http','https'], 'http://wwwproxy.sandia.gov:80');

    my $request     = HTTP::Request->new('GET', $link);
    my $response    = $agent->request($request);

    if ( $response->is_success() ) {
        my $filename        = ( split(/\//, $link) )[-1];
        my ($fqn, $fname)   = $self->create_file($response->content, $filename);
        return $fqn, $fname;
    }
    else {
        print "Failed to retrieve!\n";
        die $response->status_line;
    }

}


# this create file assumes that we are on the scot server 
# need to create a version that will upload to the api

sub create_file {
    my $self        = shift;
    my $data        = shift;
    my $name        = shift;
    my $ext         = shift; 
    my $env         = $self->env;
    my $log         = $env->log;
    my $dir         = $self->conf->{image_dir} // "/opt/scot/public/cached_images";
    my $storage     = $self->conf->{storage} // 'local';

    $log->debug("Creating File: $name");

    if ( $storage eq 'local' ) {
        if ($name =~ /^\d+$/ ) {
            # create a name with low chance of collision
            $name   = md5_hex($data);
        }
        $name = $name . ".". $ext if ( $ext );
        $log->debug("dir = $dir name = $name");
        my $fqn = join('/',$dir,$name);
        $log->debug("file at $fqn");
        open my $fh, ">", "$fqn" or die $!;
        binmode $fh;
        print   $fh $data;
        close   $fh;
        return $fqn, $name;
    }
    # do api upload
    # mojo ua -> upload img
    # get the Scot::Model::CachedImage return code
    # return the $fqn, $name
}

sub update_html {
    my $self    = shift;
    my $element = shift;
    my $fqn     = shift;
    my $fname   = shift;

    my $source  = $self->conf->{html_root} . "/cached_images/" . $fname;
    my $alt     = $element->attr('alt');
    if ( $alt ) {
        $alt    = "ScotCopy of $alt";
    }
    else {
        $alt    = "Scot Cached Image";
    }
    my $newimg  = HTML::Element->new('img', 'src'   => $source, 'alt' => $alt);
    $element->replace_with($newimg);
}


1;
